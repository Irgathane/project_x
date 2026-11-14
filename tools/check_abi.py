#!/usr/bin/env python3
"""Verify defs.qc still matches the engine's vanilla ABI layout.

The engine reads globals and entity fields *positionally*: the first 54 globals
must be globalvars_t and the first 77 entity fields must be entvars_t, in that
exact order. Anything appended after is harmless (edicts are sized from the QC
field count); anything inserted or reordered silently corrupts every builtin.

Run after touching defs.qc, before shipping a progs.dat:

    python3 tools/check_abi.py

Exit code 0 = layout intact. 1 = mismatch (the printed index is where).
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFS = ROOT / "slipgate" / "qc" / "defs.qc"
ENGINE_HEADER = ROOT / "vkQuake" / "Quake" / "progdefs.q1"

DECL = re.compile(r"^(?:\.\w+(?:\([^)]*\))?|entity|float|string|vector|void\(\))\s+(.+);$")


def parse_section(text: str) -> list[str]:
    out: list[str] = []
    for line in text.splitlines():
        s = line.strip()
        if not s or s.startswith("//") or "=" in s:
            continue
        m = DECL.match(s)
        if m:
            out += [n.strip() for n in m.group(1).split(",")]
    return out


def canonical() -> tuple[list[str], list[str]]:
    if not ENGINE_HEADER.is_file():
        sys.exit(f"ERROR: {ENGINE_HEADER} not found (is vkQuake/ checked out?)")
    body = ENGINE_HEADER.read_text()
    body = body[body.index("typedef struct"):body.index("} entvars_t;")]
    names = [m.group(2) for m in re.finditer(r"^\s+(int|float|vec3_t|string_t|func_t)\s+([a-zA-Z_0-9]+);", body, re.M)]
    split = names.index("modelindex")
    return names[:split], names[split:]


def main() -> None:
    src = DEFS.read_text()
    try:
        g = src[src.index("// ---- globals the engine writes"):src.index("// ---- entity fields")]
        f = src[src.index("// ---- entity fields"):src.index("// ---- constants ----")]
    except ValueError:
        sys.exit("ERROR: defs.qc is missing the section markers this tool looks for")

    qg, qf = parse_section(g), parse_section(f)
    cg, cf = canonical()

    ok = True
    for label, want, got in (("globals", cg, qg), ("fields", cf, qf)):
        prefix_ok = got[:len(want)] == want
        print(f"{label:8} qc={len(got):3}  canonical={len(want):2}  prefix={'OK' if prefix_ok else 'MISMATCH'}  extras={len(got)-len(want)}")
        if not prefix_ok:
            ok = False
            for i in range(min(len(want), len(got))):
                if want[i] != got[i]:
                    print(f"  first divergence at #{i}: engine expects '{want[i]}', defs.qc has '{got[i]}'")
                    break
        if len(got) < len(want):
            print(f"  MISSING {len(want)-len(got)} canonical entries — builtins will read garbage")
            ok = False

    print("\nABI layout intact." if ok else "\nABI layout BROKEN — restore vanilla order before building.")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()