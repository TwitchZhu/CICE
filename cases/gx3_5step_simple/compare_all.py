"""Write all five-step restart and step-entry comparison reports."""

import re
import subprocess
import sys
from pathlib import Path


CASE = Path(__file__).resolve().parent
ROOT = CASE.parents[1]

total = 19
completed = 0
restart_differences = 0
entrance_differences = 0
print("Checking inputs for 15 restart and 4 step-entry comparisons...", flush=True)

jax_log = CASE / "cice.runlog"
if not jax_log.is_file():
    raise SystemExit(f"ERROR: Missing JAX run log: {jax_log}")

snapshots = {}
for line in jax_log.read_text(encoding="utf-8", errors="replace").splitlines():
    match = re.match(r"\(step_entry\) complete: (\S+\.json) (\S+\.npz)$", line.strip())
    if match is None:
        continue
    metadata = CASE / match.group(1)
    data = CASE / match.group(2)
    step_match = re.match(r"step_entry_jax\.(\d{8})\.", metadata.name)
    if step_match is None:
        raise SystemExit(f"ERROR: Unexpected JAX snapshot name: {metadata}")
    step = int(step_match.group(1))
    if (step in snapshots or data != metadata.with_suffix(".npz")
            or not metadata.is_file() or not data.is_file()):
        raise SystemExit(f"ERROR: Missing or duplicate JAX snapshot at step {step}")
    snapshots[step] = metadata
if set(snapshots) != {1, 2}:
    raise SystemExit(f"ERROR: Expected JAX entrance snapshots for steps 1 and 2, "
                     f"found {sorted(snapshots)}")

for side in ("gnu", "intel"):
    directory = CASE / side / "step_entry"
    if not directory.is_dir():
        directory = CASE / side
    for step in (1, 2):
        texts = sorted(directory.glob(f"step_entry.{step:08d}.rank*.txt"))
        if not texts or any(not path.with_suffix(".bin").is_file() for path in texts):
            raise SystemExit(f"ERROR: Incomplete {side} step {step} entrance snapshot in {directory}")
    snapshots[side] = directory

print("Inputs found. Starting comparisons...", flush=True)
for step in range(1, 6):
    for label, option in (("GNU–JAX", ()), ("GNU–Intel", ("--ifort",)),
                          ("Intel–JAX", ("--intel-jax",))):
        command = [sys.executable, str(CASE / "compare_restart.py"),
                   "--step", str(step), "--all-pond-mismatches", *option]
        result = subprocess.run(command, capture_output=True, text=True,
                                encoding="utf-8", errors="replace", cwd=ROOT)
        lines = result.stdout.splitlines()
        report = next((line for line in lines if line.startswith("Comparison output:")), "")
        summary = next((line for line in reversed(lines) if line.startswith("SUMMARY ")), "")
        if not summary or result.returncode not in (0, 1):
            print(result.stdout, result.stderr, sep="\n", file=sys.stderr)
            raise SystemExit(f"ERROR: Restart comparison failed at step {step} {label} "
                             f"({completed}/{total} completed)")
        completed += 1
        restart_differences += int(result.returncode == 1)
        status = "DIFF" if result.returncode else "PASS"
        print(f"[{completed}/{total}] Restart step {step} {label}: {status}; "
              f"{summary}; {report}", flush=True)

for step in (1, 2):
    for side in ("gnu", "intel"):
        command = [sys.executable, str(CASE / "compare_step_entry.py"),
                   "--jax", str(snapshots[step]),
                   "--fortran", str(snapshots[side])]
        result = subprocess.run(command, capture_output=True, text=True,
                                encoding="utf-8", errors="replace", cwd=ROOT)
        if result.returncode:
            print(result.stdout, result.stderr, sep="\n", file=sys.stderr)
            raise SystemExit(f"ERROR: Step {step} JAX–{side} entrance comparison failed "
                             f"({completed}/{total} completed)")
        summary = next((line for line in result.stdout.splitlines()
                        if line.startswith("SUMMARY ")), "")
        if not summary:
            print(result.stdout, result.stderr, sep="\n", file=sys.stderr)
            raise SystemExit(f"ERROR: Step {step} JAX–{side} entrance report has no summary")
        differences = any(int(value) for key, value in re.findall(r"(\w+)=(\d+)", summary)
                          if key != "matched_comparisons")
        completed += 1
        entrance_differences += int(differences)
        status = "DIFF/COVERAGE" if differences else "PASS"
        report = next((line for line in result.stdout.splitlines()
                       if line.startswith("Comparison log:")), "")
        print(f"[{completed}/{total}] Entrance step {step} JAX–{side}: {status}; "
              f"{summary}; {report}", flush=True)

print(f"Completed {completed}/{total} comparisons without script errors. "
      f"Restart reports with differences: {restart_differences}/15; "
      f"entrance reports with differences or coverage gaps: {entrance_differences}/4. "
      f"Reports: {CASE / 'comparison_logs'}", flush=True)
