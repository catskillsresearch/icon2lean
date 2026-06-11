#!/usr/bin/env python3
"""Convert section 3+ algorithm math and table cells for reliable GitHub rendering."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MD = ROOT / "Courant_Ericson_1986.md"
START_LINE = 2205  # #### 3.1.1. Greatest Common Divisor


def demath_inline(text: str) -> str:
    """$`expr`$ -> `expr` (Icon/code identifiers in tables and signatures)."""

    def repl(m: re.Match[str]) -> str:
        return f"`{m.group(1)}`"

    return re.sub(r"\$`([^`]+)`\$", repl, text)


def fix_algo_signatures(text: str) -> str:
    return re.sub(
        r"\*\*([^*]+)\*\*\$`([^`]+)`\$",
        r"**\1**(`\2`)",
        text,
    )


def demath_table_row(line: str) -> str:
    if not line.strip().startswith("|"):
        return line
    return demath_inline(line)


def math_block_to_icon(body: str) -> str:
    out: list[str] = []
    for raw in body.splitlines():
        line = raw.strip()
        if not line or line.startswith(r"\begin") or line.startswith(r"\end"):
            continue
        if line.startswith("&"):
            line = line[1:].strip()
        if line in {"\\", "\\\\", "&\\", "&\\\\"}:
            continue

        line = re.sub(r"\\blacksquare\s*\\?\s*$", " ■", line)
        line = re.sub(r"\\+\s*$", "", line).strip()
        if not line:
            continue

        s = line
        s = s.replace(r"\Leftarrow", "←")
        s = s.replace(r"\Uparrow", "↑")
        s = s.replace(r"\bot", "⊥")
        s = re.sub(r"\\textbf\{([^}]*)\}", r"\1", s)
        s = s.replace(r"\mathrel{:=}", " := ")
        s = s.replace(r"\mathrel{\texttt{|||}}\mathrel{:=}", " |||:= ")
        s = s.replace(r"\mathrel{\texttt{|||}}", " ||| ")
        s = s.replace(r"\mathbin{⨸}", "⨸")
        s = s.replace(r"\mathbin{\text{rem}}", "rem")
        s = s.replace(r"\ominus", "⊖")
        s = s.replace(r"\oplus", "⊕")
        s = s.replace(r"\otimes", "⊗")
        s = re.sub(r"\\texttt\{!\}", "!", s)
        s = re.sub(r"\\texttt\{\*\}", "*", s)
        s = re.sub(r"\\texttt\{([^}]+)\}", r"\1", s)
        s = re.sub(r"\\text\{([^}]*)\}", r"\1", s)
        s = re.sub(r"\\mathrm\{([^}]*)\}", r"\1", s)
        s = re.sub(r"\\pmod\{([^}]*)\}", r"(mod \1)", s)
        s = s.replace(r"\_", "_")
        s = s.replace(r"\ne", "≠")
        s = s.replace(r"\neq", "≠")
        s = s.replace(r"\&", "&")
        s = s.replace(r"\cdot", "·")
        s = re.sub(r"\\quad+", "    ", s)
        s = re.sub(r"\\+", "", s)
        s = re.sub(r"  +", " ", s).strip()
        if s:
            out.append(s)
    return "\n".join(out)


def convert_math_fences(text: str) -> str:
    pattern = re.compile(
        r"(<div class=\"math-left\">\s*\n+)"
        r"```math\n(.*?)```\n+"
        r"(\s*</div>)",
        re.DOTALL,
    )

    def repl(m: re.Match[str]) -> str:
        icon = math_block_to_icon(m.group(2))
        if not icon:
            return m.group(0)
        return f'{m.group(1)}```icon\n{icon}\n```\n\n{m.group(3)}'

    return pattern.sub(repl, text)


def demath_all_tables(text: str) -> str:
    """Reduce math load in tables file-wide (GitHub MathJax cumulative limit)."""
    return "\n".join(demath_table_row(line) for line in text.splitlines())


def main() -> None:
    lines = MD.read_text().splitlines()
    head = "\n".join(lines[: START_LINE - 1])
    tail = "\n".join(lines[START_LINE - 1 :])

    head = demath_all_tables(head)
    tail = fix_algo_signatures(tail)
    tail = demath_all_tables(tail)
    tail = convert_math_fences(tail)

    MD.write_text(head + "\n" + tail + "\n")
    print(f"Updated {MD} from line {START_LINE}")


if __name__ == "__main__":
    main()
