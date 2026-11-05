"""Compare complete entrance snapshots; never initialize or advance CICE."""

import argparse
from collections import Counter
from datetime import datetime
import json
from pathlib import Path

import numpy as np


CASE = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument("--jax", type=Path, help="explicit step_entry_jax.*.json; otherwise newest")
parser.add_argument("--fortran", type=Path, default=CASE / "fortran_pond_debug" / "step_entry",
                    help="directory containing all rank .txt/.bin pairs from one run")
args = parser.parse_args()
if args.jax is None:
    candidates = sorted((CASE / "comparison_logs").glob("step_entry_jax.*.json"))
    if not candidates:
        raise FileNotFoundError("No JAX step entrance snapshot")
    args.jax = candidates[-1]
jmeta = json.loads(args.jax.read_text(encoding="utf-8"))
if jmeta["format"] != "CICE_STEP_ENTRY_JAX_V1":
    raise ValueError("Unknown JAX snapshot format")
step = int(jmeta["step"])
jdata = np.load(args.jax.with_suffix(".npz"), allow_pickle=False)
ilo, ihi, jlo, jhi = jmeta["physical_bounds"]
nx, ny = ihi - ilo + 1, jhi - jlo + 1
ranks = []
manifest = json.loads((CASE / "step_entry_manifest.json").read_text(encoding="utf-8"))
expected_fields = {f"{module['name']}.{field['name']}"
                   for module in manifest["modules"] for field in module["fields"]}
expected_fields.update(f"icepack_orbital.{name}" for name in ("eccen", "obliqr", "lambm0", "mvelpp"))
for path in sorted(args.fortran.glob(f"step_entry.{step:08d}.rank*.txt")):
    lines = path.read_text(encoding="utf-8").splitlines()
    data_path = path.with_suffix(".bin")
    if not lines or lines[0] != "CICE_STEP_ENTRY_V1" or not lines[-1].startswith("END "):
        raise ValueError(f"Incomplete Fortran snapshot: {path}")
    if int(lines[-1].split()[1]) != data_path.stat().st_size:
        raise ValueError(f"Truncated or mixed Fortran .txt/.bin pair: {path}")
    with data_path.open("rb") as stream:
        magic = stream.read(8)
    if magic == bytes.fromhex("0807060504030201"):
        endian = "<"
    elif magic == bytes.fromhex("0102030405060708"):
        endian = ">"
    else:
        raise ValueError(f"Unknown binary layout: {data_path}")
    fields = {}
    for line in lines[1:-1]:
        parts = line.split()
        key, kind = parts[:2]
        if key in fields:
            raise ValueError(f"Duplicate Fortran field {key} in {path}")
        if kind == "U":
            fields[key] = {"status": "unallocated"}
            continue
        if kind == "X":
            fields[key] = {"status": "skipped", "reason": " ".join(parts[2:])}
            continue
        ndim, offset, width, grid = map(int, parts[2:6])
        if kind not in "RILC" or (kind != "C" and width != 8):
            raise ValueError(f"Unsupported field encoding: {line}")
        dims = tuple(map(int, parts[6:6 + ndim]))
        lower = tuple(map(int, parts[6 + ndim:]))
        if len(dims) != ndim or len(lower) != ndim:
            raise ValueError(f"Malformed shape: {line}")
        dtype = np.dtype(f"S{width}" if kind == "C" else endian + ("f8" if kind == "R" else "i8"))
        count = int(np.prod(dims, dtype=np.int64))
        if offset < 8 or offset + count * width > data_path.stat().st_size:
            raise ValueError(f"Field exceeds binary file: {key}")
        values = (np.memmap(data_path, dtype=dtype, mode="r", offset=offset,
                            shape=dims, order="F") if count else np.empty(dims, dtype=dtype))
        fields[key] = {"status": "saved", "grid": bool(grid), "values": values,
                       "lower": lower, "kind": kind}
    rank = int(fields["layout.rank"]["values"])
    if expected_fields - fields.keys():
        raise ValueError(f"Snapshot does not cover this manifest: {path}; missing={sorted(expected_fields - fields.keys())}")
    if int(fields["layout.step"]["values"]) != step:
        raise ValueError(f"Wrong time step in {path}")
    ranks.append((rank, path, fields))
if not ranks:
    raise FileNotFoundError("No Fortran step entrance snapshots")
expected_ranks = int(ranks[0][2]["layout.nprocs"]["values"])
if sorted(rank for rank, _, _ in ranks) != list(range(expected_ranks)):
    raise ValueError("Download every MPI rank; rank files are missing or duplicated")
if any(int(fields["layout.nprocs"]["values"]) != expected_ranks for _, _, fields in ranks):
    raise ValueError("Fortran rank files have inconsistent process counts")
if len({bytes(fields["layout.run_id"]["values"]) for _, _, fields in ranks}) != 1:
    raise ValueError("Fortran rank files come from different runs")

output = CASE / "comparison_logs" / f"step_entry_compare.{datetime.now():%Y%m%d-%H%M%S-%f}.log"
counts = Counter()
used_fortran = set()


def compare_values(log, label, jvalues, fvalues, coordinates=None):
    """Report exact value/bit differences, without a floating tolerance."""
    jvalues, fvalues = np.asarray(jvalues), np.asarray(fvalues)
    if jvalues.shape != fvalues.shape:
        counts["shape_mismatch"] += 1
        log.write(f"SHAPE {label} JAX={jvalues.shape} Fortran={fvalues.shape}\n")
        return
    if jvalues.dtype.kind in "SU" and fvalues.dtype.kind in "SU":
        jvalues = np.char.rstrip(np.char.encode(jvalues, "utf-8")
                                 if jvalues.dtype.kind == "U" else jvalues, b" ")
        fvalues = np.char.rstrip(fvalues, b" ")
        equal = jvalues == fvalues
    elif jvalues.dtype.kind == "f" and fvalues.dtype.kind == "f":
        jvalues, fvalues = jvalues.astype(np.float64), fvalues.astype(np.float64)
        equal = jvalues.view(np.uint64) == fvalues.view(np.uint64)
        nonfinite = ~(np.isfinite(jvalues) & np.isfinite(fvalues))
        if np.any(nonfinite):
            counts["nonfinite"] += 1
            log.write(f"NONFINITE {label} count={int(np.count_nonzero(nonfinite))}\n")
    elif jvalues.dtype.kind in "biu" and fvalues.dtype.kind in "biu":
        equal = jvalues == fvalues
    else:
        counts["type_mismatch"] += 1
        log.write(f"TYPE {label} JAX={jvalues.dtype} Fortran={fvalues.dtype}\n")
        return
    jvalues, fvalues = np.asarray(jvalues), np.asarray(fvalues)
    equal = np.asarray(equal)
    bad = np.argwhere(~equal)
    if not np.any(~equal):
        counts["matched_comparisons"] += 1
        log.write(f"MATCH {label} count={equal.size}\n")
        return
    counts["different_comparisons"] += 1
    counts["different_values"] += int(np.count_nonzero(~equal))
    log.write(f"DIFF {label} count={int(np.count_nonzero(~equal))}/{equal.size}\n")
    for location in bad[:4]:
        index = tuple(int(x) for x in location)
        position = f"index0={index}"
        if coordinates is not None and len(index) >= 2:
            position += f" global=({coordinates[0][index[0]]},{coordinates[1][index[1]]})"
        log.write(f"  {position} JAX={jvalues[index]!r} Fortran={fvalues[index]!r}\n")
    if jvalues.dtype.kind == "f":
        finite = np.isfinite(jvalues) & np.isfinite(fvalues)
        if np.any(finite):
            with np.errstate(over="ignore", invalid="ignore"):
                difference = np.abs(jvalues[finite] - fvalues[finite])
            log.write(f"  max_abs={np.max(difference):.17e}\n")


with output.open("x", encoding="utf-8") as log:
    log.write(f"JAX metadata: {args.jax}\ncheckpoint: {jmeta['checkpoint']}\nstep={step}\n")
    for rank, path, _ in ranks:
        log.write(f"Fortran rank={rank}: {path}\n")
    log.write("Exact float64 bit comparison; strings ignore Fortran trailing padding.\n"
              "Raw entrance buffers include values reset before use; differences require a read-before-write audit.\n"
              "No unmatched or unsupported field counts as equal.\n")

    # Decomposition completeness is checked independently of field equality.
    coverage = np.zeros((nx, ny), dtype=np.int32)
    for rank, _, fields in ranks:
        ig = np.asarray(fields["layout.iglob"]["values"])
        jg = np.asarray(fields["layout.jglob"]["values"])
        bounds = np.asarray(fields["layout.bounds"]["values"])
        for block in range(bounds.shape[1]):
            fi0, fi1, fj0, fj1 = bounds[:, block] - 1
            gi = ig[fi0:fi1 + 1, block]
            gj = jg[fj0:fj1 + 1, block]
            gi, gj = gi[(gi >= 1) & (gi <= nx)], gj[(gj >= 1) & (gj <= ny)]
            coverage[np.ix_(gi - 1, gj - 1)] += 1
    if np.any(coverage != 1):
        counts["domain_coverage_gap"] += 1
        log.write(f"COVERAGE uncovered={np.count_nonzero(coverage == 0)} "
                  f"overlapping={np.count_nonzero(coverage > 1)}\n")

    for name, description in sorted(jmeta["fields"].items()):
        if description["status"] != "saved":
            counts["unsupported_jax"] += 1
            log.write(f"UNSUPPORTED {name}: {description}\n")
            continue
        group, module, variable = name.split(".", 2)
        if module == "ice_state_tracers":
            module = "ice_state"
        key = f"{module}.{variable}".lower()
        jvalues = jdata[name]
        # Python tracer slots are zero based; Fortran tracer slots are one based.
        shifted = ((module == "icepack_tracers" and variable.startswith("nt_"))
                   or (module == "ice_state" and variable == "nt_strata"))
        if shifted:
            jvalues = jvalues.astype(np.int64) + 1
            log.write(f"INDEX_BASE {name}: JAX + 1 before comparison\n")
        found = False
        for rank, _, fields in ranks:
            label = f"{name} -> {key} rank={rank}"
            field = fields.get(key)
            if field is None:
                counts["missing_fortran"] += 1
                log.write(f"MISSING {label}\n")
                continue
            found = True
            used_fortran.add(key)
            if field["status"] != "saved":
                counts["unavailable_fortran"] += 1
                log.write(f"UNAVAILABLE {label} JAX_shape={jvalues.shape} reason={field}\n")
                continue
            fvalues = field["values"]
            if not field["grid"]:
                compare_values(log, label, jvalues, fvalues)
                continue
            if (jvalues.ndim != fvalues.ndim - 1 or jvalues.ndim < 2
                    or jvalues.shape[2:] != fvalues.shape[2:-1]
                    or jvalues.shape[:2] != (ihi + ilo + 1, jhi + jlo + 1)):
                counts["shape_mismatch"] += 1
                log.write(f"GRID_SHAPE {label} JAX={jvalues.shape} Fortran={fvalues.shape}\n")
                continue
            ig = np.asarray(fields["layout.iglob"]["values"])
            jg = np.asarray(fields["layout.jglob"]["values"])
            bounds = np.asarray(fields["layout.bounds"]["values"])
            for block in range(bounds.shape[1]):
                fi0, fi1, fj0, fj1 = bounds[:, block] - 1
                gi, gj = ig[:, block], jg[:, block]
                ji, jj = ilo + gi - 1, jlo + gj - 1
                # Match actual outer halo slots, including signed tripole j.
                ii, ij = np.arange(len(gi)), np.arange(len(gj))
                if gi[fi0] == 1:
                    ji = np.where(ii < fi0, ilo + ii - fi0, ji)
                if gi[fi1] == nx:
                    ji = np.where(ii > fi1, ihi + ii - fi1, ji)
                if gj[fj0] == 1:
                    jj = np.where(ij < fj0, jlo + ij - fj0, jj)
                if gj[fj1] == ny:
                    jj = np.where(ij > fj1, jhi + ij - fj1, jj)
                valid_i = (ji >= 0) & (ji < jvalues.shape[0])
                valid_j = (jj >= 0) & (jj < jvalues.shape[1])
                valid_i &= ~((ii >= fi0) & (ii <= fi1) & ((gi < 1) | (gi > nx)))
                valid_j &= ~((ij >= fj0) & (ij <= fj1) & ((gj < 1) | (gj > ny)))
                if not np.all(valid_i) or not np.all(valid_j):
                    counts["unmapped_grid_slots"] += 1
                    log.write(f"UNMAPPED_GRID {label} block={block + 1}\n")
                fi, fj = np.flatnonzero(valid_i), np.flatnonzero(valid_j)
                jblock = jvalues[np.ix_(ji[fi], jj[fj])]
                fblock = np.asarray(fvalues[..., block])[np.ix_(fi, fj)]
                # Separate physical points from halo-only differences.
                physical = ((fi[:, None] >= fi0) & (fi[:, None] <= fi1)
                            & (fj[None, :] >= fj0) & (fj[None, :] <= fj1))
                for label_suffix, mask in (("physical", physical), ("halo", ~physical)):
                    # Keep i/j axes so locations can be mapped back to global coordinates.
                    if not np.any(mask):
                        continue
                    mask = mask.reshape(mask.shape + (1,) * (jblock.ndim - 2))
                    fselected = np.where(mask, fblock, jblock)
                    compare_values(log, f"{label} block={block + 1} {label_suffix}",
                                   jblock, fselected, (gi[fi], gj[fj]))
        if not found:
            counts["unmatched_jax_fields"] += 1

    for key in sorted(set().union(*(set(fields) for _, _, fields in ranks)) - used_fortran):
        if not key.startswith("layout."):
            counts["unmatched_fortran_fields"] += 1
            log.write(f"FORTRAN_ONLY {key}\n")
    summary = "SUMMARY " + " ".join(f"{key}={value}" for key, value in sorted(counts.items()))
    log.write(summary + "\n")
    log.write("This is a coverage and equality report, not proof that every saved buffer is a live physics input.\n")
    if any(value for key, value in counts.items() if key != "matched_comparisons"):
        log.write("RESULT: differences or coverage gaps remain; entrance equality is NOT established.\n")
    else:
        log.write("RESULT: exported fields agree; audit the manifest and private/local inputs before claiming full coverage.\n")
jdata.close()
print(summary)
print(f"Comparison log: {output}")
