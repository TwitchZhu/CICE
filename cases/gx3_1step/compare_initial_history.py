"""Compare the Fortran and CICE-JAX gx3_1step initial history files.

Run this after run.py has produced the JAX iceh_ic file. The comparison reads
both files at their native grid points without interpolation. It checks the
initial history fields, not every in-memory state array at time-loop entry.
"""

from pathlib import Path

import netCDF4
import numpy as np


CASE = Path(__file__).resolve().parent
ROOT = CASE.parents[1]
REFERENCE = ROOT.parent / "CICE/cice-dirs/runs/gx3_1step/history/iceh_ic.2005-01-01-00000.nc"
RESULT = CASE / "history/iceh_ic.2005-01-01-00000.nc"
RTOL = 1e-6
ATOL = 1e-10

for path in (REFERENCE, RESULT):
    if not path.is_file():
        raise FileNotFoundError(path)

passed = 0
failed = 0
with netCDF4.Dataset(REFERENCE) as original, netCDF4.Dataset(RESULT) as migrated:
    original.set_auto_mask(False)
    migrated.set_auto_mask(False)
    all_names = sorted(set(original.variables) | set(migrated.variables))
    for name in all_names:
        if name not in original.variables or name not in migrated.variables:
            side = "Fortran" if name in original.variables else "JAX"
            print(f"{name}: FAIL  only in {side}")
            failed += 1
            continue

        left = np.asarray(original.variables[name][...])
        right = np.asarray(migrated.variables[name][...])
        if left.shape != right.shape:
            print(f"{name}: FAIL  shape Fortran={left.shape} JAX={right.shape}")
            failed += 1
            continue

        if left.dtype.kind not in "iufcb" or right.dtype.kind not in "iufcb":
            good = np.array_equal(left, right)
            print(f"{name}: {'PASS' if good else 'FAIL'}  shape={left.shape} exact comparison")
            passed += int(good)
            failed += int(not good)
            continue

        finite = np.isfinite(left) & np.isfinite(right)
        same_special = (
            np.array_equal(np.isnan(left), np.isnan(right))
            and np.array_equal(np.isposinf(left), np.isposinf(right))
            and np.array_equal(np.isneginf(left), np.isneginf(right))
        )
        close = np.isclose(left[finite], right[finite], rtol=RTOL, atol=ATOL)
        bad = int(np.count_nonzero(~close)) + int(np.count_nonzero(
            np.isfinite(left) != np.isfinite(right)
        ))
        if not same_special and bad == 0:
            bad = 1
        delta = np.abs(left[finite] - right[finite])
        max_abs = float(np.max(delta)) if delta.size else 0.0
        scale = np.maximum(np.maximum(np.abs(left[finite]), np.abs(right[finite])), ATOL)
        max_rel = float(np.max(delta / scale)) if delta.size else 0.0
        good = same_special and bad == 0
        print(f"{name}: {'PASS' if good else 'FAIL'}  shape={left.shape} "
              f"bad={bad} max_abs={max_abs:.6e} max_rel={max_rel:.6e}")
        passed += int(good)
        failed += int(not good)

print(f"SUMMARY  pass={passed}  fail={failed}  rtol={RTOL}  atol={ATOL}")
raise SystemExit(1 if failed else 0)
