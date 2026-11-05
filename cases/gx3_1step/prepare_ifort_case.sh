#!/usr/bin/env bash
set -euo pipefail

# Run from the existing Fortran gx3_1step case on the server.
if [[ ${PWD##*/} != gx3_1step ]]; then
    echo 'Run this script from the original Fortran gx3_1step case.' >&2
    exit 1
fi
for file in cice.settings cice.build cice.run cice.submit setup_run_dirs.csh Makefile makdep.c ice_in env.xingyi_gnu; do
    test -f "$file"
done
for path in ../gx3_ifort ../../runs/gx3_ifort; do
    if [[ -e $path || -L $path ]]; then
        echo "Already exists; leaving it unchanged: $path" >&2
        exit 1
    fi
done

mkdir ../gx3_ifort
cp -pL cice.settings cice.build cice.run cice.submit setup_run_dirs.csh Makefile makdep.c ice_in ../gx3_ifort/
if [[ -d casescripts ]]; then
    cp -RLp casescripts ../gx3_ifort/
fi
cp -pL ice_in ../gx3_ifort/ice_in.gnu_baseline

sed 's/gx3_1step/gx3_ifort/g; s/xingyi_gnu/xingyi_intel/g' cice.settings > ../gx3_ifort/cice.settings
sed -i -E 's/^(setenv ICE_ENVNAME)[[:space:]]+.*/\1 intel/; s/^(setenv ICE_CLEANBUILD)[[:space:]]+.*/\1 true/' ../gx3_ifort/cice.settings
sed 's/gx3_1step/gx3_ifort/g; s/xingyi_gnu/xingyi_intel/g' cice.run > ../gx3_ifort/cice.run
sed 's/gx3_1step/gx3_ifort/g; s/xingyi_gnu/xingyi_intel/g' cice.submit > ../gx3_ifort/cice.submit

sed \
    -e '/^module load mpi\/mpich\//c\module purge\nif ($status != 0) exit 2\nmodule load intel/oneapi2023.2_noimpi\nif ($status != 0) exit 2\nmodule load mpi/mpich/4.1.2-icc-oneapi2023.2-ch4\nif ($status != 0) exit 2' \
    -e '/^module load hdf5\//c\module load hdf5/1.14.3-icc-oneapi2023.2-mpich-4.1.2-ch4\nif ($status != 0) exit 2' \
    -e '/^module load netcdf\//c\module load netcdf/4.9.2-icc-oneapi2023.2-mpich-4.1.2-ch4\nif ($status != 0) exit 2' \
    -e 's/^setenv ICE_MACHINE_ENVNAME .*/setenv ICE_MACHINE_ENVNAME intel/' \
    -e 's/^setenv ICE_MACHINE_ENVINFO .*/setenv ICE_MACHINE_ENVINFO "ifort 2021.10.0, mpich 4.1.2"/' \
    env.xingyi_gnu > ../gx3_ifort/env.xingyi_intel

cat > ../gx3_ifort/Macros.xingyi_intel <<'EOF'
CPP         := fpp
CPPDEFS     := -DFORTRANUNDERSCORE ${ICE_CPPDEFS}
CFLAGS      := -c
FIXEDFLAGS  := -fixed -132
FREEFLAGS   := -free
FFLAGS      := -fpp -fp-model precise -convert big_endian -assume byterecl -traceback
FFLAGS_NOOPT := -O0

ifeq ($(ICE_BLDDEBUG), true)
  FFLAGS += -O0 -g -check bounds -fpe0
  CFLAGS += -O0
else
  FFLAGS += -O2
  CFLAGS += -O2 -fp-model precise
endif

SCC   := icc
SFC   := ifort
MPICC := mpicc
MPIFC := mpif90
ifeq ($(ICE_COMMDIR), mpi)
  FC := $(MPIFC)
  CC := $(MPICC)
else
  FC := $(SFC)
  CC := $(SCC)
endif
LD := $(FC)

INCLDIR += $(shell nf-config --fflags)
SLIBS   := $(shell nf-config --flibs) $(shell nc-config --libs)

ifeq ($(ICE_THREADED), true)
  LDFLAGS += -qopenmp
  CFLAGS  += -qopenmp
  FFLAGS  += -qopenmp
endif
EOF

# Change only run length and output controls; retain the original physics.
sed -i -E \
    -e "s|^([[:space:]]*npt_unit[[:space:]]*=).*|\1 '1'|" \
    -e 's|^([[:space:]]*npt[[:space:]]*=).*|\1 1|' \
    -e "s|^([[:space:]]*restart_dir[[:space:]]*=).*|\1 './restart/'|" \
    -e "s|^([[:space:]]*history_dir[[:space:]]*=).*|\1 './history/'|" \
    -e "s|^([[:space:]]*incond_dir[[:space:]]*=).*|\1 './history/'|" \
    -e "s|^([[:space:]]*pointer_file[[:space:]]*=).*|\1 './ice.restart_file'|" \
    -e "s|^([[:space:]]*dumpfreq[[:space:]]*=).*|\1 '1','x','x','x','x'|" \
    -e 's|^([[:space:]]*dumpfreq_n[[:space:]]*=).*|\1 1,1,1,1,1|' \
    -e "s|^([[:space:]]*histfreq[[:space:]]*=).*|\1 '1','x','x','x','x'|" \
    -e 's|^([[:space:]]*histfreq_n[[:space:]]*=).*|\1 1,1,1,1,1|' \
    -e 's|^([[:space:]]*hist_avg[[:space:]]*=).*|\1 .false.,.true.,.true.,.true.,.true.|' \
    -e 's|^([[:space:]]*history_precision[[:space:]]*=).*|\1 8|' \
    -e 's|^([[:space:]]*diagfreq[[:space:]]*=).*|\1 1|' \
    ../gx3_ifort/ice_in

cat > ../gx3_ifort/README.case <<'EOF'
Intel toolchain comparison, copied from gx3_1step.
One step; original physics, input data, MPI layout, and source tree retained.
Compiler: ifort 2021.10.0, -O2 -fp-model precise.
MPI: MPICH 4.1.2, Intel build.
HDF5: 1.14.3; NetCDF-C: 4.9.2; NetCDF-Fortran: 4.6.1.
GNU baseline NetCDF-Fortran is 4.5.3, so this compares toolchains.
ice_in.gnu_baseline preserves the original namelist for comparison.
The source tree is shared with the original case; do not edit it between builds.
EOF

echo 'Prepared ../gx3_ifort. No compiler or model has been run.'
echo 'Review the settings and namelist diff before building:'
echo '  cd ../gx3_ifort'
echo '  cat cice.settings'
echo '  diff -u ice_in.gnu_baseline ice_in'
echo '  csh ./cice.build'
echo 'After COMPILE SUCCESSFUL: csh ./cice.submit'
