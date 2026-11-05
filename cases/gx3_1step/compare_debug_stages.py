"""Compare the two models' debug_model output at each one-step checkpoint.

Enable debug_model in both ice_in files, run both models, and copy the new
Fortran cice.runlog.* into the downloaded gx3_1step logs directory first.
"""

import atexit
from datetime import datetime
import math
import re
from pathlib import Path


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
FORTRAN_LOGS = CASE.parents[1].parent / "CICE/cice-dirs/cases/gx3_1step/logs"
JAX_LOG = CASE / "cice.runlog"
RTOL = 1e-6
ATOL = 1e-10
CHECKPOINTS = (
    "beginning time step", "post prep_radiation", "post step_therm1",
    "post biogeochemistry", "post step_therm2", "post step_dyn_horiz",
    "post step_dyn_ridge", "post dynamics", "post step_radiation",
    "post coupling_prep",
)

logs = sorted(FORTRAN_LOGS.glob("cice.runlog.*"))
if not logs:
    raise FileNotFoundError(f"No Fortran run log in {FORTRAN_LOGS}")
fortran_log = logs[-1]
if not JAX_LOG.is_file():
    raise FileNotFoundError(JAX_LOG)

log_print(f"Fortran: {fortran_log}")
log_print(f"JAX:     {JAX_LOG}")

results = []
for path in (fortran_log, JAX_LOG):
    stages = {}
    stage = None
    category = None
    with path.open(encoding="utf-8", errors="replace") as log:
        for raw_line in log:
            line = raw_line.strip()
            if line.startswith("(print_state)"):
                line = line.removeprefix("(print_state)").strip()
            if line in CHECKPOINTS:
                stage = line
                if stage in stages:
                    raise ValueError(f"Repeated checkpoint {stage!r} in {path}")
                stages[stage] = {}
                category = None
                continue
            if stage is None:
                continue

            match = re.match(r"n\s*=\s*(\d+)$", line)
            if match:
                category = int(match.group(1))
                continue

            key = None
            value = None
            match = re.match(r"Lat, Lon \(degrees\):\s*(\S+)\s+(\S+)", line)
            if match:
                stages[stage]["latitude"] = float(match.group(1).replace("D", "E"))
                stages[stage]["longitude"] = float(match.group(2).replace("D", "E"))
                continue
            match = re.match(r"(qice|qsnow|sice),\s*cat\s+(\d+)\s+layer\s+(\d+)\s+(\S+)", line)
            if match:
                key = f"{match.group(1)}[cat={match.group(2)},layer={match.group(3)}]"
                value = match.group(4)
            else:
                match = re.match(r"(aice|aice0|aicen|vicen|vsnon|Tsfcn|afsdn|uvel\(i,j\)|vvel\(i,j\))\s+(\S+)", line)
                if match:
                    key = match.group(1)
                    if key in ("aicen", "vicen", "vsnon", "Tsfcn", "afsdn"):
                        key = f"{key}[cat={category}]"
                    value = match.group(2)
                else:
                    match = re.match(r"([A-Za-z][A-Za-z0-9]*)\s*=\s*(\S+)$", line)
                    if match:
                        key, value = match.groups()
            if key is not None:
                stages[stage][key] = float(value.replace("D", "E"))
    results.append(stages)

fortran, jax = results
if not fortran or not jax:
    raise ValueError("Missing debug output. Check that debug_model is true in both runs.")

first_bad = None
for stage in dict.fromkeys((*fortran, *jax)):
    if stage not in fortran or stage not in jax:
        log_print(f"{stage}: MISSING in {'Fortran' if stage not in fortran else 'JAX'}")
        first_bad = first_bad or stage
        continue
    left, right = fortran[stage], jax[stage]
    bad = []
    for key in sorted(left.keys() | right.keys()):
        if key not in left or key not in right:
            bad.append((key, left.get(key), right.get(key)))
        elif not math.isclose(left[key], right[key], rel_tol=RTOL, abs_tol=ATOL):
            bad.append((key, left[key], right[key]))
    log_print(f"{stage}: {len(left.keys() & right.keys())} shared values, {len(bad)} differences")
    if stage == "post step_dyn_horiz":
        for key in ("uvel(i,j)", "vvel(i,j)"):
            log_print(f"  {key}: Fortran={left.get(key)} JAX={right.get(key)}")
    for key, a, b in bad[:15]:
        log_print(f"  {key}: Fortran={a} JAX={b}")
    if len(bad) > 15:
        log_print(f"  ... {len(bad) - 15} more differences")
    if bad:
        first_bad = first_bad or stage

log_print(f"First differing checkpoint: {first_bad or 'none at this diagnostic point'}")
