"""Inspect the saved stresses and velocities from the ndte=1 experiment.

Download the Fortran restart from the same run as its latest debug log.
This script only reads files; it does not initialize or run either model.
"""

import atexit
from datetime import datetime
import re
from pathlib import Path

import netCDF4
import numpy as np


CASE = Path(__file__).resolve().parent
OUTPUT_DIR = CASE / "comparison_logs"
OUTPUT_DIR.mkdir(exist_ok=True)
OUTPUT_LOG = OUTPUT_DIR / f"{Path(__file__).stem}.{datetime.now():%Y%m%d-%H%M%S-%f}.log"
output_log = OUTPUT_LOG.open("x", encoding="utf-8")
atexit.register(output_log.close)


def log_print(*args):
    print(*args)
    print(*args, file=output_log, flush=True)


log_print(f"Comparison output: {OUTPUT_LOG}")
REFERENCE_ROOT = CASE.parents[1].parent / "CICE/cice-dirs"
logs = sorted((REFERENCE_ROOT / "cases/gx3_1step/logs").glob("cice.runlog.*"))
if not logs:
    raise FileNotFoundError("No downloaded Fortran cice.runlog.*")
LOGS = (logs[-1], CASE / "cice.runlog")
RESTARTS = (
    REFERENCE_ROOT / "runs/gx3_1step/restart/iced.2005-01-01-03600.nc",
    CASE / "restart/iced.2005-01-01-03600.nc",
)
RTOL = 1e-6
ATOL = 1e-10

points = []
log_velocities = []
for side, path in zip(("Fortran", "JAX"), LOGS):
    log_print(f"{side} log: {path}")
    content = path.read_text(encoding="utf-8", errors="replace")
    for name in ("npt", "ndtd", "ndte"):
        match = re.search(rf"^\s*{name}\s*=\s*(\d+)", content, re.MULTILINE)
        if match is None or int(match.group(1)) != 1:
            raise ValueError(f"{side}: this check requires {name}=1 in the run log")
    checkpoints = re.findall(
        r"\(print_state\)\s+post step_dyn_horiz\s*\n(.*?)"
        r"(?=\(print_state\)\s+post step_dyn_ridge)", content, re.DOTALL,
    )
    if len(checkpoints) != 1:
        raise ValueError(f"{side}: expected one complete post step_dyn_horiz checkpoint")
    checkpoint = checkpoints[0]
    match = re.search(r"Global i and j:\s*(\d+)\s+(\d+)", checkpoint)
    if match is None:
        raise ValueError(f"{side}: diagnostic grid point missing")
    points.append(tuple(map(int, match.groups())))
    velocities = {}
    for name in ("uvel", "vvel"):
        match = re.search(rf"\b{name}\(i,j\)\s+(\S+)", checkpoint)
        if match is None:
            raise ValueError(f"{side}: {name} missing from checkpoint")
        velocities[name] = float(match.group(1).replace("D", "E"))
    log_velocities.append(velocities)

if points[0] != points[1]:
    raise ValueError(f"Diagnostic points differ: {points}")
global_i, global_j = points[0]
# The Fortran global indices are 1-based; restart arrays have no halo cells.
i, j = global_i - 1, global_j - 1
log_print(f"Diagnostic global point: i={global_i}, j={global_j}")

fields = []
stress_names = [f"{stem}_{k}" for stem in ("stressp", "stressm", "stress12")
                for k in range(1, 5)]
names = ["iceumask", "uvel", "vvel", *stress_names]
for side, path, velocities in zip(("Fortran", "JAX"), RESTARTS, log_velocities):
    log_print(f"{side} restart: {path}")
    values = {}
    with netCDF4.Dataset(path) as dataset:
        dataset.set_auto_mask(False)
        for name in names:
            if name not in dataset.variables:
                raise ValueError(f"{side}: restart field {name} missing")
            variable = dataset.variables[name]
            data = np.asarray(variable[:])
            if variable.dimensions == ("ni", "nj"):
                data = data.T
            elif variable.dimensions != ("nj", "ni"):
                raise ValueError(f"{side} {name}: unexpected dimensions {variable.dimensions}")
            values[name] = data
        for name in ("uvel", "vvel"):
            saved = float(values[name][j, i])
            expected = velocities[name]
            if not np.isclose(saved, expected, rtol=RTOL, atol=ATOL):
                raise ValueError(
                    f"{side} restart does not match its log: {name} at the diagnostic "
                    f"point is {saved}, but log has {expected}. Use the restart "
                    "from the same ndte=1 run; the filename is reused across runs."
                )
    fields.append(values)
log_print("Both restart velocities match their ndte=1 logs.")

original, migrated = fields
stress_stencil_bad = 0
for name in names:
    left, right = original[name], migrated[name]
    if left.shape != right.shape:
        raise ValueError(f"{name}: shapes differ: {left.shape} vs {right.shape}")
    finite = np.isfinite(left) & np.isfinite(right)
    close = finite & np.isclose(left, right, rtol=RTOL, atol=ATOL)
    difference = np.abs(np.where(finite, left, 0.0) - np.where(finite, right, 0.0))
    worst_j, worst_i = np.unravel_index(np.argmax(difference), difference.shape)
    log_print(f"{name}: bad={np.count_nonzero(~close)}/{left.size} "
          f"nonfinite={np.count_nonzero(~finite)} max_abs={difference[worst_j, worst_i]:.6e} "
          f"at global i={worst_i + 1}, j={worst_j + 1}")
    # Fortran stepu uses stresses from T(i,j), T(i+1,j), T(i,j+1), T(i+1,j+1).
    offsets = ((0, 0), (1, 0), (0, 1), (1, 1)) if name in stress_names else ((0, 0),)
    for di, dj in offsets:
        ii, jj = i + di, j + dj
        if ii >= left.shape[1] or jj >= left.shape[0]:
            raise ValueError("Diagnostic stencil crosses the file boundary; halo mapping is needed")
        good = bool(close[jj, ii])
        if name in stress_names:
            stress_stencil_bad += int(not good)
        log_print(f"  i={ii + 1}, j={jj + 1}: {'PASS' if good else 'FAIL'} "
              f"Fortran={left[jj, ii]:.16e} JAX={right[jj, ii]:.16e}")

log_print(f"Stress differences in the four-cell momentum stencil: {stress_stencil_bad}/48")
log_print("Matching stresses narrow the next check to momentum inputs and stepu; "
      "differing stresses require checking stress and its inputs as well.")
