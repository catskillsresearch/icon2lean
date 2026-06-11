#!/usr/bin/env python3
"""Convert math-left $$ blocks to GitHub-safe ```math fences and simplify underscores."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MD = ROOT / "Courant_Ericson_1986.md"

MATH_LEFT = re.compile(
    r'(<div class="math-left">\s*\n+)\$\$(.*?)\$\$(\s*\n</div>)',
    re.DOTALL,
)

CHAR137 = r"\mathord{\texttt{\char137}}"


def escape_text_underscores(body: str) -> str:
    def repl(m: re.Match[str]) -> str:
        inner = re.sub(r"(?<!\\)_", r"\\_", m.group(1))
        return r"\text{" + inner + "}"

    prev = None
    while prev != body:
        prev = body
        body = re.sub(r"\\text\{([^{}]*)\}", repl, body)
    return body


def simplify_underscores(body: str) -> str:
    body = body.replace(
        r'\text{"is"}' + CHAR137 + r'\text{"zero"}' + CHAR137 + r'\text{""}',
        r'\text{"is_zero_"}',
    )
    body = re.sub(
        r'\\text\{"([^"]+)"\}' + re.escape(CHAR137) + r'\\text\{""\}',
        r'\\text{"\1_"}',
        body,
    )
    body = body.replace(
        r"\text{poly}" + CHAR137 + r"\text{of}",
        r"\text{poly\_of}",
    )
    body = body.replace(
        r"\text{'}" + CHAR137 + r"\text{'0123456789'}",
        r"\text{'_0123456789'}",
    )
    return body


def convert_math_left_blocks(text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        body = match.group(2).strip("\n")
        body = simplify_underscores(body)
        body = escape_text_underscores(body)
        return match.group(1) + "```math\n" + body + "\n```\n" + match.group(3)

    return MATH_LEFT.sub(repl, text)


def main() -> None:
    original = MD.read_text(encoding="utf-8")
    fixed = convert_math_left_blocks(original)
    if fixed != original:
        MD.write_text(fixed, encoding="utf-8")
        print(f"Updated {MD}")
    else:
        print("No changes needed")


if __name__ == "__main__":
    main()
