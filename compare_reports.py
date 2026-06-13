#!/usr/bin/env python3
"""Diff Icon vs Lean report stdout (run_report.sh vs run_lean_report.sh)."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def run(cmd: list[str]) -> str:
    p = subprocess.run(cmd, capture_output=True, text=True, cwd=ROOT, timeout=120)
    if p.returncode != 0 and not p.stdout:
        print(p.stderr, file=sys.stderr)
        raise SystemExit(p.returncode)
    return p.stdout


def normalize_line(line: str) -> str:
    line = line.strip()
    if not line:
        return ""
    # Icon timing line from MOD_RS
    if re.match(r"^\[\d+ msecs\]$", line):
        return "[0 msecs]"
    # EUCLID Q negative fraction formatting: ((-16)/9) vs (-16/9)
    line = re.sub(r"\(\((-?\d+)\)/(\d+)\)", r"(\1/\2)", line)
    return re.sub(r"\s+", " ", line)


def main() -> int:
    try:
        icon = run(["./run_report.sh"])
    except SystemExit as e:
        print("Icon report failed (is icon installed?)", file=sys.stderr)
        return int(e.args[0]) if e.args else 1

    lean = run(["./run_lean_report.sh"])

    icon_lines = [normalize_line(l) for l in icon.splitlines()]
    lean_lines = [normalize_line(l) for l in lean.splitlines()]
    icon_lines = [l for l in icon_lines if l]
    lean_lines = [l for l in lean_lines if l]

    if icon_lines == lean_lines:
        print(f"Reports match ({len(icon_lines)} lines).")
        return 0

    print(f"Mismatch: Icon {len(icon_lines)} lines, Lean {len(lean_lines)} lines")
    n = max(len(icon_lines), len(lean_lines))
    mismatches = 0
    for i in range(n):
        a = icon_lines[i] if i < len(icon_lines) else "<missing>"
        b = lean_lines[i] if i < len(lean_lines) else "<missing>"
        if a != b:
            mismatches += 1
            if mismatches <= 20:
                print(f"--- line {i + 1} ---")
                print(f"  Icon: {a}")
                print(f"  Lean: {b}")
    if mismatches > 20:
        print(f"  ... and {mismatches - 20} more")
    return 1


if __name__ == "__main__":
    sys.exit(main())
