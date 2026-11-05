"""Run the gx3 comparison using this case's ice_in (currently five steps)."""

import argparse
import os
import sys
import traceback
from contextlib import redirect_stdout
from datetime import datetime
from pathlib import Path

import jax
import jaxlib


CASE = Path(__file__).resolve().parent
ROOT = CASE.parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from cicecore.cicedyn.general import ice_init, ice_step_mod
from cicecore.cicedyn.infrastructure import ice_domain
from cicecore.drivers.standalone.cice.CICE import icemodel
from cicecore.shared import ice_calendar, ice_fileunits, ice_init_column


parser = argparse.ArgumentParser()
parser.add_argument("--diagnose", choices=("T", "F"), default="F",
                    help="log synchronized stage and memory diagnostics (T or F)")
args = parser.parse_args()

os.chdir(CASE)
Path("history_multistep_diag").mkdir(exist_ok=True)
Path("restart_multistep_diag").mkdir(exist_ok=True)

# Initialization calls these readers without arguments. Read this case's ice_in.
ice_init.input_data.__defaults__ = ("ice_in",)
ice_init_column.input_zbgc.__defaults__ = ("ice_in",)
ice_domain.init_domain_blocks.__defaults__ = ("ice_in",)

# Ordinary evolution: all temporary causal interventions are disabled.
ice_step_mod.DEBUG_REPLAY_ATMO_COEFFICIENTS = False
ice_step_mod.DEBUG_REPLAY_ATMO_PSI = False
ice_step_mod.DEBUG_REPLAY_ATMO_MATH = False

log_stamp = datetime.now().strftime('%Y%m%d-%H%M%S-%f')

print(f"Running gx3 comparison case: {CASE}", flush=True)
print(f"JAX default backend: {jax.default_backend()}", flush=True)
print(f"JAX devices: {jax.devices()}", flush=True)
try:
    with open("cice.multistep_diag.runlog", "w", encoding="utf-8") as log:
        try:
            with redirect_stdout(log):
                ice_fileunits.nu_diag = log
                print("Diagnostic round: multistep-pond-v1; points=(68,2),(67,9),(52,8); all categories")
                print("Runtime:", sys.version, "JAX:", jax.__version__, "jaxlib:", jaxlib.__version__)
                print("Backend:", jax.default_backend(), "devices:", jax.devices())
                print("JAX x64 before initialization:", jax.config.x64_enabled)
                for name in ("JAX_ENABLE_X64", "JAX_PLATFORMS", "XLA_FLAGS",
                             "CUDA_VISIBLE_DEVICES", "NVIDIA_TF32_OVERRIDE"):
                    print(f"{name}={os.environ.get(name, '<unset>')}")
                print("Atmospheric coefficient replay requested:",
                      ice_step_mod.DEBUG_REPLAY_ATMO_COEFFICIENTS,
                      "reference=fortran_pond_debug/cice.runlog.261030-201956")
                print("Atmospheric psi replay requested:",
                      ice_step_mod.DEBUG_REPLAY_ATMO_PSI,
                      "reference=fortran_pond_debug/cice.runlog.261030-201956")
                print("Atmospheric math return replay requested:",
                      ice_step_mod.DEBUG_REPLAY_ATMO_MATH,
                      "reference=comparison_logs/stability_probe_fortran.log")
                try:
                    icemodel(diagnose=args.diagnose == "T")
                finally:
                    jax.effects_barrier()
                print(f"Final calendar: istep={ice_calendar.istep}, npt={ice_calendar.npt}, "
                      f"stop_now={ice_calendar.stop_now}", flush=True)
        except BaseException:
            log.write(f"Run stopped at calendar step {ice_calendar.istep1}:\n")
            traceback.print_exc(file=log)
            log.flush()
            raise
finally:
    # Archive existing diagnostic lines; physics switches live in ice_in.
    if bool(ice_init.debug_model):
        with open("cice.multistep_diag.runlog", encoding="utf-8") as run_log:
            lines = run_log.readlines()
        Path("comparison_logs").mkdir(exist_ok=True)
        full_log = Path("comparison_logs") / f"run.{log_stamp}.log"
        with full_log.open("x", encoding="utf-8") as archived_log:
            archived_log.writelines(lines)
        print(f"Full run log: {CASE / full_log}", flush=True)
        for prefix, stem in (("(pond_stage)", "pond_stages"),
                             ("(pond_therm1)", "pond_inputs"),
                             ("(atmo_jax)", "atmo_inputs"),
                             ("(picard_jax)", "picard_inputs"),
                             ("(picard_entry_jax)", "picard_entry"),
                             ("(atmo_coeff_replay)", "atmo_coeff_replay"),
                             ("(atmo_psi_replay)", "atmo_psi_replay"),
                             ("(atmo_math_replay)", "atmo_math_replay")):
            selected = [line for line in lines if line.startswith(prefix)]
            if selected:
                Path("comparison_logs").mkdir(exist_ok=True)
                output = Path("comparison_logs") / f"{stem}.{log_stamp}.log"
                with output.open("x", encoding="utf-8") as diagnostic_log:
                    diagnostic_log.write(Path("ice_in").read_text(encoding="utf-8") + "\n")
                    diagnostic_log.writelines(selected)
                print(f"Diagnostic log: {CASE / output}", flush=True)
    print(f"Diagnostic log: {CASE / 'cice.multistep_diag.runlog'}", flush=True)
