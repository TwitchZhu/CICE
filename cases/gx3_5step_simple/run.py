"""Run the independent gx3 five-step pond diagnostic case."""

import argparse
import os
import sys
import traceback
from contextlib import redirect_stdout
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
Path("history").mkdir(exist_ok=True)
Path("restart").mkdir(exist_ok=True)

# Initialization calls these readers without arguments. Read this case's ice_in.
ice_init.input_data.__defaults__ = ("ice_in",)
ice_init_column.input_zbgc.__defaults__ = ("ice_in",)
ice_domain.init_domain_blocks.__defaults__ = ("ice_in",)

# Ordinary evolution: all temporary causal interventions are disabled.
ice_step_mod.DEBUG_REPLAY_ATMO_COEFFICIENTS = False
ice_step_mod.DEBUG_REPLAY_ATMO_PSI = False
ice_step_mod.DEBUG_REPLAY_ATMO_MATH = False

print(f"Running gx3 comparison case: {CASE}", flush=True)
print(f"JAX default backend: {jax.default_backend()}", flush=True)
print(f"JAX devices: {jax.devices()}", flush=True)
try:
    with open("cice.runlog", "w", encoding="utf-8") as log:
        try:
            with redirect_stdout(log):
                ice_fileunits.nu_diag = log
                print("Diagnostic round: gx3_5step_simple-v1; points=(68,2),(67,9),(52,8); all categories")
                print("Runtime:", sys.version, "JAX:", jax.__version__, "jaxlib:", jaxlib.__version__)
                print("Backend:", jax.default_backend(), "devices:", jax.devices())
                print("JAX x64 before initialization:", jax.config.x64_enabled)
                for name in ("JAX_ENABLE_X64", "JAX_PLATFORMS", "XLA_FLAGS",
                             "CUDA_VISIBLE_DEVICES", "NVIDIA_TF32_OVERRIDE"):
                    print(f"{name}={os.environ.get(name, '<unset>')}")
                print("Atmospheric coefficient replay requested:",
                      ice_step_mod.DEBUG_REPLAY_ATMO_COEFFICIENTS)
                print("Atmospheric psi replay requested:",
                      ice_step_mod.DEBUG_REPLAY_ATMO_PSI)
                print("Atmospheric math return replay requested:",
                      ice_step_mod.DEBUG_REPLAY_ATMO_MATH)
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
    print(f"Diagnostic log: {CASE / 'cice.runlog'}", flush=True)
