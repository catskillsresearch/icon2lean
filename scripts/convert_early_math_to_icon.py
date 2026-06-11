#!/usr/bin/env python3
"""Convert sections 1–2 ```math blocks to ```icon to reduce GitHub MathJax load."""

from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from section3_github_fixup import (
    START_LINE,
    convert_math_fences,
    fix_icon_subscripts,
    prose_input_output_plain,
)

ROOT = Path(__file__).resolve().parents[1]
MD = ROOT / "Courant_Ericson_1986.md"

MATH_FENCE = re.compile(r"```math\n(.*?)```\n", re.DOTALL)


def convert_all_math_fences(text: str) -> str:
    from section3_github_fixup import math_block_to_icon

    def repl(m: re.Match[str]) -> str:
        icon = math_block_to_icon(m.group(1))
        if not icon:
            return m.group(0)
        return f"```icon\n{icon}\n```\n"

    return MATH_FENCE.sub(repl, text)


def fix_icon_blocks(text: str) -> str:
    parts = re.split(r"(```icon\n.*?```\n)", text, flags=re.DOTALL)

    def fix_block(block: str) -> str:
        if not block.startswith("```icon"):
            return block
        body = block[7:-4]  # after ```icon\n and before ```
        body = fix_icon_subscripts(body)
        body = body.replace(" ||| := ", " |||:= ")
        body = body.replace("||| := ", "|||:= ")
        return f"```icon\n{body}```\n"

    return "".join(fix_block(p) if p.startswith("```icon") else p for p in parts)


def main() -> None:
    lines = MD.read_text().splitlines()
    head = "\n".join(lines[: START_LINE - 1])
    tail = "\n".join(lines[START_LINE - 1 :])

    head = convert_all_math_fences(head)
    head = convert_math_fences(head)  # any remaining div-wrapped math

    tail = prose_input_output_plain(tail)
    combined = fix_icon_blocks(head + "\n" + tail)

    MD.write_text(combined + "\n")
    print(f"Converted early math blocks; updated {MD}")


if __name__ == "__main__":
    main()
