"""Replay logged stability inputs; do not initialize or advance CICE.

Run from the repository root. Upload comparison_logs/stability_probe_inputs.txt
and stability_probe.F90 to the Fortran case for the matching standalone probe.
"""

from functools import partial
from pathlib import Path
import re
import sys

import jax
import jax.numpy as jnp
import numpy as np

jax.config.update("jax_enable_x64", True)
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from icepack.columnphysics.icepack_atmo import compute_stability_function
from icepack.columnphysics import icepack_parameters


FIELDS = (
    "hol", "pih", "psi_original", "psi_split", "exp_arg", "exp_value",
    "stable_a", "stable_b", "stable_c", "stable_sum", "xd_arg", "xd",
    "momentum_arg", "log_m", "atan_xd", "scalar_arg", "log_s",
)


@partial(jax.jit, static_argnames=("qty",))
def probe(hol, pih, qty):
    _, original = compute_stability_function(qty, hol, {"pih": pih})
    # Candidate boundaries for probing XLA reassociation/fusion, not a model fix.
    barrier = jax.lax.optimization_barrier
    exp_arg = barrier(-0.35 * hol)
    exp_value = barrier(jnp.exp(exp_arg))
    stable_a = barrier(0.7 * hol)
    stable_b = barrier(0.75 * barrier(hol - 14.3))
    stable_c = barrier(stable_b * exp_value)
    stable_sum = barrier(stable_a + stable_c)
    psi_stable = -barrier(stable_sum + 10.7)
    xd_arg = barrier(1.0 - barrier(16.0 * hol))
    xd = barrier(jnp.sqrt(jnp.maximum(barrier(jnp.sqrt(jnp.abs(xd_arg))), 1.0)))
    xd_squared = barrier(xd * xd)
    momentum_arg = barrier(barrier(barrier(1.0 + barrier(xd * barrier(2.0 + xd)))
                                   * barrier(1.0 + xd_squared)) / 8.0)
    log_m = barrier(jnp.log(momentum_arg))
    atan_xd = barrier(jnp.arctan(xd))
    scalar_arg = barrier(barrier(1.0 + xd_squared) / 2.0)
    log_s = barrier(jnp.log(scalar_arg))
    if qty == "momentum":
        psi_unstable = barrier(barrier(log_m - barrier(2.0 * atan_xd)) + pih)
    else:
        psi_unstable = barrier(2.0 * log_s)
    stable = jnp.where(hol >= 0.0, 1.0, 0.0)
    split = barrier(barrier(psi_stable * stable)
                    + barrier((1.0 - stable) * psi_unstable))
    return jnp.stack((hol, pih, original, split, exp_arg, exp_value,
                      stable_a, stable_b, stable_c, stable_sum, xd_arg, xd,
                      momentum_arg, log_m, atan_xd, scalar_arg, log_s), axis=-1)


CASE = Path(__file__).resolve().parent
fortran_path = sorted((CASE / "fortran_pond_debug").glob("cice.runlog.*"))[-1]
jax_path = sorted((CASE / "comparison_logs").glob("atmo_inputs.*.log"))[-1]
records = []
for path, prefix in ((fortran_path, "(atmo_fortran)"), (jax_path, "(atmo_jax)")):
    rows = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith(prefix):
            continue
        values = {name: float(value) for name, value in re.findall(
            r"(\w+)=\s*([-+\d.Ee]+)", line)}
        if 1 <= values["record"] <= 5:
            key = tuple(int(values[name]) for name in ("step", "i", "j", "cat", "record"))
            rows[key] = values
    records.append(rows)
if not records[0] or records[0].keys() != records[1].keys():
    raise ValueError("Fortran/JAX stability iteration records do not match")

keys = sorted(records[0])
pih = float(icepack_parameters.p5 * icepack_parameters.pi)
input_path = CASE / "comparison_logs/stability_probe_inputs.txt"
output_path = CASE / "comparison_logs/stability_probe_jax.log"
with input_path.open("w", encoding="utf-8") as inputs, output_path.open("w", encoding="utf-8") as log:
    log.write(f"Fortran source log: {fortran_path}\nJAX source log: {jax_path}\n")
    log.write(f"JAX={jax.__version__} backend={jax.default_backend()} x64={jax.config.x64_enabled}\n")
    for kind, qty, hol_name, psi_name in (
        (1, "momentum", "holm", "psimh"), (2, "scalar", "hols", "psixh"),
    ):
        hols = []
        for key in keys:
            f, j = records[0][key], records[1][key]
            if f[hol_name] != j[hol_name]:
                raise ValueError(f"Different input {hol_name} at {key}; inspect upstream first")
            hols.append(f[hol_name])
        values = np.asarray(probe(jnp.asarray(hols), jnp.full((len(keys),), pih), qty))
        for key, row in zip(keys, values):
            f, j = records[0][key], records[1][key]
            ids = " ".join(str(value) for value in (*key, kind))
            inputs.write(f"{ids} {f[hol_name]:.17e} {pih:.17e} {f[psi_name]:.17e} {j[psi_name]:.17e}\n")
            step, i, j_index, cat, record = key
            log.write(f"(stability_jax) step={step} i={i} j={j_index} cat={cat} record={record} kind={kind} "
                      + " ".join(f"{name}={value:.17e}" for name, value in zip(FIELDS, row))
                      + f" full_fortran={f[psi_name]:.17e} full_jax={j[psi_name]:.17e}"
                      + f" original_matches_full={row[2] == j[psi_name]}"
                      + f" split_matches_fortran={row[3] == f[psi_name]}\n")
print(f"Probe inputs: {input_path}")
print(f"Probe output: {output_path}")
