"""Compare paired GNU, Intel and JAX restarts after collecting all three runs.

Run after the selected model outputs have been produced/downloaded. It reports every
variable, including variables missing on either side, and exits nonzero on
any mismatch. Both files are read as stored; no interpolation is applied.
"""

import argparse
import atexit
from datetime import datetime
from pathlib import Path
import re

import netCDF4
import numpy as np


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--all-pond-mismatches", action="store_true",
                    help="log every apnd/hpnd mismatch and group categories by grid cell")
parser.add_argument("--step", type=int, choices=range(1, 6), default=1,
                    help="hourly step to compare in the five-step experiment (default: 1)")
pair = parser.add_mutually_exclusive_group()
pair.add_argument("--ifort", action="store_true", help="compare GNU with Intel")
pair.add_argument("--intel-jax", action="store_true", help="compare Intel with JAX; explicit paths required")
parser.add_argument("--reference", type=Path, help="explicit left restart file")
parser.add_argument("--result", type=Path, help="explicit right restart file")
parser.add_argument("--reference-log", type=Path, help="complete run log for the left restart")
parser.add_argument("--result-log", type=Path, help="complete run log for the right restart")
args = parser.parse_args()
explicit = (args.reference, args.result, args.reference_log, args.result_log)
if any(path is not None for path in explicit) and not all(path is not None for path in explicit):
    parser.error("Provide all four explicit restart/log paths together")
if args.intel_jax and not all(path is not None for path in explicit):
    parser.error("--intel-jax requires all four explicit restart/log paths")
if args.ifort and args.step != 1 and not all(path is not None for path in explicit):
    parser.error("Multi-step Intel comparison requires explicit restart/log paths")


CASE = Path(__file__).resolve().parent
OUTPUT_DIR = CASE / "comparison_logs"
OUTPUT_DIR.mkdir(exist_ok=True)
log_name = "compare_intel_jax" if args.intel_jax else ("compare_gnu_ifort" if args.ifort else Path(__file__).stem)
OUTPUT_LOG = OUTPUT_DIR / f"{log_name}.{datetime.now():%Y%m%d-%H%M%S-%f}.log"
output_log = OUTPUT_LOG.open("x", encoding="utf-8")
atexit.register(output_log.close)


def log_print(*args):
    print(*args)
    print(*args, file=output_log, flush=True)


ROOT = CASE.parents[1]
filename = f"iced.2005-01-01-{args.step * 3600:05d}.nc"
REFERENCE = CASE / "fortran_pond_debug/5step/restart_5step" / filename
RESULT = CASE / "restart_5step" / filename
left_label = "Intel" if args.intel_jax else "GNU"
right_label = "Intel" if args.ifort else "JAX"
if args.ifort:
    RESULT = CASE.parent / "gx3_ifort/restart" / filename
if args.reference is not None:
    REFERENCE, RESULT = args.reference, args.result
RTOL = 1e-6
ATOL = 1e-10

log_print(f"Comparison output: {OUTPUT_LOG}")
log_print(f"{left_label} restart: {REFERENCE}")
log_print(f"{right_label} restart: {RESULT}")
log_print(f"Requested step: {args.step}")

# The same restart filename is reused by the full and pond-isolation runs.
fortran_logs = sorted((CASE / "fortran_pond_debug/5step").glob("cice.runlog.*"))
if args.reference_log is None and not fortran_logs:
    raise FileNotFoundError("No downloaded Fortran cice.runlog.*")
run_options = []
result_log = CASE / "cice.runlog"
if args.ifort and args.result_log is None:
    intel_logs = sorted((CASE.parent / "gx3_ifort/logs").glob("cice.runlog.*"))
    if not intel_logs:
        raise FileNotFoundError("No downloaded Intel cice.runlog.*")
    result_log = intel_logs[-1]
log_print("Confirm source/input hashes and actual compiler/library versions separately.")
reference_log = args.reference_log if args.reference_log is not None else fortran_logs[-1]
result_log = args.result_log if args.result_log is not None else result_log
for side, path in ((left_label, reference_log), (right_label, result_log)):
    content = path.read_text(encoding="utf-8", errors="replace")
    options = {}
    for name in ("npt", "npt_unit", "year_init", "month_init", "day_init", "sec_init",
                 "istep0", "ndtd", "ndte", "ktherm", "advection", "kridge"):
        match = re.search(rf"^\s*{name}\s*=\s*(\S+)", content, re.MULTILINE)
        if match is None:
            raise ValueError(f"{side}: {name} missing in {path}")
        options[name] = match.group(1).strip("'\"")
    log_print(f"{side} log: {path}")
    for name in ("dt", "runtype", "tr_pond_lvl", "bfbflag", "frzpnd"):
        match = re.search(rf"^\s*{name}\s*=\s*(\S+)", content, re.MULTILINE)
        if match is None:
            raise ValueError(f"{side}: {name} missing in {path}")
        value = match.group(1).strip("'\"")
        options[name] = float(value.replace("D", "E").replace("d", "e")) if name == "dt" else value
    if args.ifort:
        match = re.search(r"Processors:\s+total\s*=\s*(\d+)", content)
        if match is None:
            raise ValueError(f"{side}: processor count missing in {path}")
        options["nprocs"] = int(match.group(1))
    log_print(f"{side} configuration: {options}")
    run_options.append(options)
    if "CICE COMPLETED SUCCESSFULLY" not in content:
        raise ValueError(f"{side}: run did not finish successfully")
    if side == "JAX":
        for label in ("Atmospheric coefficient replay requested",
                      "Atmospheric psi replay requested",
                      "Atmospheric math return replay requested"):
            if f"{label}: False" not in content:
                raise ValueError(f"JAX: replay is enabled or its status is missing: {label}")
if args.ifort and args.reference is None:
    if (run_options[0]["npt"], run_options[1]["npt"]) != ("5", "1"):
        raise ValueError("Expected GNU five-step baseline and Intel one-step run")
    log_print("Comparing step one; total run length differs intentionally (GNU=5, Intel=1).")
if any(run_options[0][key] != run_options[1][key]
       for key in run_options[0] if not (args.ifort and args.reference is None and key == "npt")):
    raise ValueError("Run configurations differ. Download the matching Fortran log and restart.")
if run_options[0]["npt"] != "5" or run_options[0]["npt_unit"] != "1":
    raise ValueError("Expected the completed five-step experiment")

for path in (REFERENCE, RESULT):
    if not path.is_file():
        raise FileNotFoundError(path)

passed = 0
failed = 0
pond_mismatch_cells = {}
with netCDF4.Dataset(REFERENCE) as original, netCDF4.Dataset(RESULT) as migrated:
    original.set_auto_mask(False)
    migrated.set_auto_mask(False)
    for dataset in (original, migrated):
        actual_time = tuple(int(dataset.getncattr(name)) for name in ("myear", "mmonth", "mday", "msec"))
        if actual_time != (2005, 1, 1, args.step * 3600):
            raise ValueError(f"Restart time does not match requested step: {actual_time}")
    for name in ("istep1", "myear", "mmonth", "mday", "msec"):
        left = original.getncattr(name) if name in original.ncattrs() else None
        right = migrated.getncattr(name) if name in migrated.ncattrs() else None
        good = left == right
        log_print(f"attribute {name}: {'PASS' if good else 'FAIL'}  {left_label}={left}  {right_label}={right}")
        passed += int(good)
        failed += int(not good)

    all_names = sorted(set(original.variables) | set(migrated.variables))
    for name in all_names:
        if name not in original.variables or name not in migrated.variables:
            side = left_label if name in original.variables else right_label
            log_print(f"{name}: FAIL  only in {side}")
            failed += 1
            continue

        left = np.asarray(original.variables[name][:])
        right = np.asarray(migrated.variables[name][:])
        if left.shape != right.shape or original.variables[name].dimensions != migrated.variables[name].dimensions:
            log_print(f"{name}: FAIL  shape/dimensions "
                      f"{left_label}={left.shape}/{original.variables[name].dimensions} "
                      f"{right_label}={right.shape}/{migrated.variables[name].dimensions}")
            failed += 1
            continue

        finite = np.isfinite(left) & np.isfinite(right)
        same_special = np.array_equal(np.isnan(left), np.isnan(right)) and np.array_equal(
            np.isposinf(left), np.isposinf(right)
        ) and np.array_equal(np.isneginf(left), np.isneginf(right))
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
        log_print(f"{name}: {'PASS' if good else 'FAIL'}  shape={left.shape} "
              f"bad={bad} max_abs={max_abs:.6e} max_rel={max_rel:.6e}")
        if not good:
            mismatch = ~np.isclose(left, right, rtol=RTOL, atol=ATOL, equal_nan=True)
            positions = np.flatnonzero(mismatch)
            absolute = np.abs(np.where(finite, left, 0.0)
                              - np.where(finite, right, 0.0))
            score = np.where(finite, absolute, np.inf).ravel()
            worst = positions[np.argsort(-score[positions], kind="stable")]
            show_all = args.all_pond_mismatches and name in ("apnd", "hpnd")
            if not show_all:
                worst = worst[:5]
            dimensions = original.variables[name].dimensions
            label = f"All {len(worst)} mismatches" if show_all else "Largest differences"
            log_print(f"  {label} (file dimension indices are 1-based):")
            for position in worst:
                index = np.unravel_index(position, left.shape)
                coordinates = dict(zip(dimensions, index))
                if show_all:
                    if not all(dim in coordinates for dim in ("ni", "nj", "ncat")):
                        raise ValueError(f"Cannot group pond coordinates: {dimensions}")
                    cell = (int(coordinates["nj"]) + 1, int(coordinates["ni"]) + 1)
                    categories = pond_mismatch_cells.setdefault(cell, {})
                    categories.setdefault(name, set()).add(int(coordinates["ncat"]) + 1)
                location = ", ".join(f"{dim}={value + 1}" for dim, value in coordinates.items())
                log_print(f"    {location}: {left_label}={left[index]:.16e} {right_label}={right[index]:.16e}")
                if name in ("apnd", "hpnd"):
                    for side, dataset in ((left_label, original), (right_label, migrated)):
                        pond = {}
                        for field in ("aicen", "vicen", "alvl", "apnd", "hpnd", "ipnd"):
                            variable = dataset.variables[field]
                            if any(dim not in coordinates for dim in variable.dimensions):
                                raise ValueError(f"{side} {field}: cannot map dimensions to {dimensions}")
                            pond[field] = float(variable[tuple(coordinates[dim] for dim in variable.dimensions)])
                        log_print(f"      {side}: " + " ".join(
                            f"{field}={value:.16e}" for field, value in pond.items()))
                        # Level-ice ponds: apnd is relative to level ice, hpnd to pond area.
                        pond_area = pond["aicen"] * pond["alvl"] * pond["apnd"]
                        log_print(f"        pond_area_per_grid_area={pond_area:.16e} "
                                  f"pond_volume_per_grid_area={pond_area * pond['hpnd']:.16e}")
        passed += int(good)
        failed += int(not good)

    if args.all_pond_mismatches:
        log_print(f"POND MISMATCH CELLS: count={len(pond_mismatch_cells)} "
                  "(global 1-based i,j; categories grouped per cell)")
        for (j, i), categories in sorted(pond_mismatch_cells.items()):
            details = " ".join(
                f"{field}_cats=" + ",".join(str(n) for n in sorted(values))
                for field, values in sorted(categories.items()))
            log_print(f"  i={i} j={j} {details}")

    # Supplemental diagnostics for the current tr_pond_lvl case. These do not
    # replace the individual tracer comparisons or change the exit status.
    pond_fields = ("aicen", "alvl", "apnd", "hpnd")
    if all(name in dataset.variables for dataset in (original, migrated)
           for name in pond_fields):
        dimensions = original.variables["apnd"].dimensions
        shape = original.variables["apnd"].shape
        if not all(dataset.variables[name].dimensions == dimensions
                   and dataset.variables[name].shape == shape
                   for dataset in (original, migrated) for name in pond_fields):
            raise ValueError("Pond diagnostics require matching category/grid dimensions")
        pond_states = [{name: np.asarray(dataset.variables[name][:]) for name in pond_fields}
                       for dataset in (original, migrated)]
        log_print("POND DIAGNOSTICS (level-ice ponds; original PASS/FAIL unchanged)")
        # Same definitions as in compute_ponds_lvl: volume is m3 per m2 of grid.
        areas = [state["aicen"] * state["alvl"] * state["apnd"] for state in pond_states]
        volumes = [area * state["hpnd"] for area, state in zip(areas, pond_states)]
        for label, values in (("pond_area_per_grid_area", areas),
                              ("pond_volume_per_grid_area", volumes)):
            left, right = values
            finite = np.isfinite(left) & np.isfinite(right)
            close = finite & np.isclose(left, right, rtol=RTOL, atol=ATOL)
            difference = np.abs(np.where(finite, left, 0.0)
                               - np.where(finite, right, 0.0))
            log_print(f"  {label}: bad={np.count_nonzero(~close)}/{left.size} "
                      f"nonfinite={np.count_nonzero(~finite)} max_abs_finite={difference.max():.6e}")
            score = np.where(finite, difference, np.inf).ravel()
            for position in np.argsort(-score, kind="stable")[:5]:
                index = np.unravel_index(position, shape)
                location = ", ".join(f"{dim}={value + 1}"
                                     for dim, value in zip(dimensions, index))
                log_print(f"    {location}: {left_label}={left[index]:.16e} {right_label}={right[index]:.16e}")
        for field in ("apnd", "hpnd"):
            left, right = (state[field] for state in pond_states)
            bad = ~(np.isfinite(left) & np.isfinite(right)
                    & np.isclose(left, right, rtol=RTOL, atol=ATOL))
            log_print(f"  Depth context at {field} mismatches: count={np.count_nonzero(bad)}")
            if np.any(bad):
                for side, state in zip((left_label, right_label), pond_states):
                    depth = state["hpnd"][bad]
                    finite_depth = depth[np.isfinite(depth)]
                    if finite_depth.size:
                        log_print(f"    {side}: hpnd_min={finite_depth.min():.16e} "
                                  f"hpnd_max={finite_depth.max():.16e} "
                                  f"nonfinite={np.count_nonzero(~np.isfinite(depth))}")
                # Reference constants in icepack_parameters; hpmin is only a
                # depth screen, not the full snow/lid-adjusted radiation mask.
                depths = [state["hpnd"] for state in pond_states]
                tiny = bad & (np.abs(depths[0]) <= 1e-11) & (np.abs(depths[1]) <= 1e-11)
                shallow = bad & (depths[0] < 0.005) & (depths[1] < 0.005)
                log_print(f"    both_abs_hpnd_le_puny(1e-11 m)={np.count_nonzero(tiny)} "
                          f"both_hpnd_lt_hpmin(0.005 m)={np.count_nonzero(shallow)}")

log_print(f"SUMMARY  pass={passed}  fail={failed}  rtol={RTOL}  atol={ATOL}")
raise SystemExit(1 if failed else 0)
