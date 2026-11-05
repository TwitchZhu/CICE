#!/usr/bin/env bash
set -euo pipefail

# Run in the server's cice-dirs/cases directory, using an existing working case.
if [[ $# != 2 ]]; then
    echo 'Usage: bash gx3_5step_simple/prepare_fortran_case.sh SOURCE_CASE NEW_CASE' >&2
    exit 1
fi
source_case=$1
new_case=$2
for name in "$source_case" "$new_case"; do
    if [[ ! $name =~ ^[A-Za-z0-9_-]+$ ]]; then
        echo 'Use case names, not paths.' >&2
        exit 1
    fi
done
package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ -e $new_case || -L $new_case || -e ../runs/$new_case || -L ../runs/$new_case ]]; then
    echo "Case or run directory already exists: $new_case" >&2
    exit 1
fi
case_files=(cice.settings cice.build cice.run cice.submit setup_run_dirs.csh Makefile makdep.c)
for file in "${case_files[@]}"; do
    test -f "$source_case/$file"
done
test -f "$package_dir/fortran_pond_debug/ice_in"
shopt -s nullglob
environment_files=("$source_case"/env.* "$source_case"/Macros.*)
if (( ${#environment_files[@]} < 2 )); then
    echo 'Source case must contain its env.* and Macros.* files.' >&2
    exit 1
fi

mkdir "$new_case"
for file in "${case_files[@]}"; do
    cp -pL "$source_case/$file" "$new_case/$file"
done
cp -pL "${environment_files[@]}" "$new_case/"
if [[ -d $source_case/casescripts ]]; then
    cp -RLp "$source_case/casescripts" "$new_case/"
fi
# Replace only case identifiers/paths; retain the source compiler and MPI settings.
for file in "${case_files[@]}"; do
    sed -i "s/$source_case/$new_case/g" "$new_case/$file"
done
for file in "$new_case"/env.* "$new_case"/Macros.*; do
    sed -i "s/$source_case/$new_case/g" "$file"
done
sed -i -E 's/^(setenv ICE_CLEANBUILD)[[:space:]]+.*/\1 true/' "$new_case/cice.settings"
cp -Rp "$package_dir/fortran_pond_debug" "$new_case/"
cp "$package_dir/fortran_pond_debug/ice_in" "$new_case/ice_in"
printf 'Five-step diagnostics copied from %s. Not built or submitted.\n' "$source_case" > "$new_case/README.case"
echo "Prepared $new_case. Check ICE_CASEDIR/ICE_RUNDIR/ICE_OBJDIR, install diagnostic sources, then build and submit."
