#!/usr/bin/env bash
set -euo pipefail

# Run from the server's cice-dirs/cases directory. No JAX installation is needed.
source_dir=${1:-../../CICE}
machine=${2:-xingyi}
case_parent=${3:-.}
package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_dir=$(cd -- "$source_dir" && pwd)
test -f "$source_dir/cice.setup"

# Pin the namelist inputs instead of silently using a different CICE configuration.
for name in gx3 diag1 run5day; do
    if ! diff --strip-trailing-cr -q "$package_dir/reference/set_nml.$name" "$source_dir/configuration/scripts/options/set_nml.$name" >/dev/null; then
        echo "Configuration differs from reference: set_nml.$name" >&2
        exit 1
    fi
done
for item in 'ice_in configuration/scripts/ice_in' 'quick_suite.ts configuration/scripts/tests/quick_suite.ts' 'version.txt cicecore/version.txt'; do
    read -r saved original <<< "$item"
    if ! diff --strip-trailing-cr -q "$package_dir/reference/$saved" "$source_dir/$original" >/dev/null; then
        echo "Configuration differs from reference: $original" >&2
        exit 1
    fi
done

for compiler in gnu intel; do
    for prefix in env Macros; do
        if [[ ! -f $source_dir/configuration/scripts/machines/$prefix.${machine}_$compiler ]]; then
            echo "Missing machine file: $prefix.${machine}_$compiler (see README)" >&2
            exit 1
        fi
    done
    if [[ -e $case_parent/gx3_5day_$compiler || -L $case_parent/gx3_5day_$compiler ]]; then
        echo "Case already exists: $case_parent/gx3_5day_$compiler" >&2
        exit 1
    fi
done
mkdir -p "$case_parent"
case_parent=$(cd -- "$case_parent" && pwd)
for compiler in gnu intel; do
    (
        cd "$source_dir"
        csh ./cice.setup --case "$case_parent/gx3_5day_$compiler" \
            -m "$machine" -e "$compiler" -p 8x2 -g gx3 -s diag1,run5day --ignore-user-set
    )
    (
        cd "$case_parent/gx3_5day_$compiler"
        mkdir evidence
        cp ice_in cice.settings env.* Macros.* evidence/
        csh -f <<'CSH'
source ./cice.settings
if (-e ${ICE_RUNDIR}) then
    echo "Run directory already exists; archive it before building: ${ICE_RUNDIR}"
    exit 1
endif
CSH
    )
done
echo "Prepared GNU and Intel cases. Nothing built or submitted. See README for the run order."
