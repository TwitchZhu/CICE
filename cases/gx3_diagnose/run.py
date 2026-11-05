"""Run gx3 remap with synchronized memory and compile diagnostics."""

import argparse
import logging
import os
import sys
import traceback
from contextlib import redirect_stdout
from pathlib import Path

import jax


CASE = Path(__file__).resolve().parent
ROOT = CASE.parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from cicecore.cicedyn.general import ice_init
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
logging.basicConfig(filename="jax_compiles.log", filemode="w", level=logging.WARNING,
                    format="%(asctime)s %(message)s", force=True)
jax.config.update("jax_log_compiles", True)

# Initialization calls these readers without arguments. Read this case's ice_in.
ice_init.input_data.__defaults__ = ("ice_in",)
ice_init_column.input_zbgc.__defaults__ = ("ice_in",)
ice_domain.init_domain_blocks.__defaults__ = ("ice_in",)

print(f"Running gx3 diagnostic case: {CASE}", flush=True)
print(f"JAX default backend: {jax.default_backend()}", flush=True)
print(f"JAX devices: {jax.devices()}", flush=True)
try:
    with open("cice.runlog", "w", encoding="utf-8") as log:
        try:
            with redirect_stdout(log):
                ice_fileunits.nu_diag = log
                icemodel(diagnose=args.diagnose == "T")
                print(f"Final calendar: istep={ice_calendar.istep}, npt={ice_calendar.npt}, "
                      f"stop_now={ice_calendar.stop_now}", flush=True)
        except BaseException:
            log.write(f"Run stopped at calendar step {ice_calendar.istep1}:\n")
            traceback.print_exc(file=log)
            log.flush()
            raise
finally:
    print(f"Diagnostic log: {CASE / 'cice.runlog'}", flush=True)
    print(f"JAX compile log: {CASE / 'jax_compiles.log'}", flush=True)
