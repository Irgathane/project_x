#!/usr/bin/env python3
"""Stamp progs.dat with the vanilla NQ ABI marker (crc = 5927).

Why this exists
---------------
vkQuake (and QuakeSpasm-style engines) refuse to load server gamecode whose
header CRC is not PROGHEADER_CRC (5927):

    Host_Error: progs.dat system vars have been modified, progdefs.h is out of date

fteqcc computes that CRC over every definition in the progs, so the moment a mod
adds its own globals or entity fields the value differs — and fteqcc says so:
"Warning: progs CRC not recognised from quake nor clones". The field is only an
ABI *marker*: the engine compares the number and nothing else, then reads globals
and entity fields positionally.

So this is safe **only if** your first 54 globals and 77 entity fields are the
vanilla ones, in the vanilla order (extras appended after are fine, because the
engine sizes edicts from the QC field count). tools/check_abi.py verifies that.

Usage:
    python3 tools/fix_progs_crc.py                      # slipgate/progs.dat
    python3 tools/fix_progs_crc.py path/to/progs.dat
    python3 tools/fix_progs_crc.py --check              # report, change nothing
"""
import argparse
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT = ROOT / "slipgate" / "progs.dat"
PROGHEADER_CRC = 5927  # vkQuake: Quake/progdefs.q1
KNOWN = {
    5927: "NetQuake (vanilla)",
    54730: "QuakeWorld",
    22390: "FTE full CSQC",
    52195: "DarkPlaces CSQC",
    26940: "prerelease Quake",
    32401: "Tenebrae",
}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("progs", nargs="?", type=Path, default=DEFAULT)
    ap.add_argument("--check", action="store_true", help="report only")
    ap.add_argument("--allow-unknown", action="store_true",
                    help="stamp even if the header doesn't look like a QC progs file")
    args = ap.parse_args()

    if not args.progs.is_file():
        sys.exit(f"ERROR: {args.progs} not found — build progs first (fteqcc progs.src)")

    data = bytearray(args.progs.read_bytes())
    if len(data) < 60:
        sys.exit(f"ERROR: {args.progs} is only {len(data)} bytes, not a progs.dat")

    version, crc = struct.unpack("<ii", data[:8])
    entityfields = struct.unpack("<i", data[56:60])[0]
    known = KNOWN.get(crc, "unknown")
    print(f"{args.progs.name}: version={version} crc={crc} ({known}) entityfields={entityfields}")

    if version != 6 and not args.allow_unknown:
        sys.exit("ERROR: version != 6 — this doesn't look like Quake 1 gamecode; pass --allow-unknown to force")
    if entityfields < 77 and not args.allow_unknown:
        sys.exit(f"ERROR: entityfields={entityfields} < 77 — defs.qc is missing vanilla entity fields; "
                 "stamping the ABI marker would corrupt the layout")

    if crc == PROGHEADER_CRC:
        print("already stamped — nothing to do")
        return
    if args.check:
        print(f"WOULD STAMP crc {crc} -> {PROGHEADER_CRC}")
        return

    struct.pack_into("<i", data, 4, PROGHEADER_CRC)
    args.progs.write_bytes(bytes(data))
    print(f"stamped crc {crc} -> {PROGHEADER_CRC} (vanilla NQ ABI marker)")
    print("the engine will now load it; field order is what actually matters at runtime")


if __name__ == "__main__":
    main()