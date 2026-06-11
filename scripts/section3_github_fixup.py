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


KEEP_MATH = re.compile(
    r"\\|[_^]|\\equiv|\\pmod|\\frac|\\sum|\\cdot|\\in\b|\\bmod|\\neq|\\mathcal|\\text|\\left|\\right"
)


def demath_simple_inline(text: str) -> str:
    """Drop math delimiters when the expression is a plain identifier or number."""

    def repl(m: re.Match[str]) -> str:
        content = m.group(1)
        if KEEP_MATH.search(content):
            return m.group(0)
        return f"`{content}`"

    return re.sub(r"\$`([^`]+)`\$", repl, text)


def fix_algo_signatures(text: str) -> str:
    text = re.sub(
        r"\*\*([^*]+)\*\*\$`([^`]+)`\$",
        r"**\1**(\2)",
        text,
    )
    return re.sub(
        r"\*\*([^*]+)\*\*\(`\(([^)]+)\)`\)",
        r"**\1**(\2)",
        text,
    )


def demath_table_row(line: str) -> str:
    if not line.strip().startswith("|"):
        return line
    return demath_inline(line)


def remath_table_row(line: str) -> str:
    """`expr` -> $`expr`$ inside table rows (GitHub inline math)."""
    if not line.strip().startswith("|") or "|:--" in line:
        return line

    def repl(m: re.Match[str]) -> str:
        return f"$`{m.group(1)}`$"

    return re.sub(r"`([^`]+)`", repl, line)


def remath_all_tables(text: str) -> str:
    return "\n".join(remath_table_row(line) for line in text.splitlines())


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
        s = s.replace(r"\mathrel{+{:=}}", " +:= ")
        s = s.replace(r"\mathrel{\texttt{|||}}\mathrel{:=}", " |||:= ")
        s = s.replace(r"\mathrel{\texttt{|||}}", " |||")
        s = s.replace(r"\mathrel{\texttt{||}}", " ||")
        s = s.replace(r"\mathrel{:=}", " := ")
        s = re.sub(r"\\mathrel\{[^{}]+\}", "", s)
        s = s.replace('proc("div_" ||', 'proc("div_" ||')
        s = re.sub(r'proc\("div_"\},', 'proc("div_" ||', s)
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
        s = fix_icon_subscripts(s)
        if s:
            out.append(s)
    return "\n".join(out)


def fix_icon_subscripts(text: str) -> str:
    """LaTeX _{foo} → Icon _foo inside code blocks."""
    prev = None
    while prev != text:
        prev = text
        text = re.sub(
            r"_\{([^{}]+)\}",
            lambda m: "_" + m.group(1).replace(" ", "_"),
            text,
        )
    return text


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


def prose_input_output_plain(text: str) -> str:
    """Replace algorithm I/O lines that use math with Unicode plain text."""
    replacements = [
        (
            r"Input: integer \$`N = 2\^m`$, polynomial \$`a\(x\) = \\sum_\{i=0\}\^\{N-1\} a_i x\^i`$, primitive \$`N`\$th root of unity \$`\\omega`\$",
            "Input: integer N = 2^m, polynomial a(x) = Σ_{i=0}^{N−1} a_i x^i, primitive Nth root of unity ω",
        ),
        (
            r"Output: array \$`A = \(A_0, \\ldots, A_\{N-1\}\)`\$ where \$`A_k = a\(\\omega\^k\)`\$",
            "Output: array A = (A₀, …, A_{N−1}) where A_k = a(ω^k)",
        ),
        (
            r"Input: integer \$`N = 2\^m`$, sample values \$`B = \(b_0, \\ldots, b_\{N-1\}\)`$, primitive \$`N`\$th root of unity \$`\\omega`\$",
            "Input: integer N = 2^m, sample values B = (b₀, …, b_{N−1}), primitive Nth root of unity ω",
        ),
        (
            r"Output: \$`a\(x\) = \\sum_\{i=0\}\^\{N-1\} a_i x\^i`\$ where \$`a\(\\omega\^k\) = b_k`\$ for \$`k = 0, \\ldots, N-1`\$",
            "Output: a(x) = Σ_{i=0}^{N−1} a_i x^i where a(ω^k) = b_k for k = 0, …, N−1",
        ),
        (
            r"Input: \$`a\(t\) \\bmod t\^\{2\^n\} = \\sum_\{i=0\}\^\{2\^n-1\} a_i t\^i`$, \$`a_0 \\neq 0`\$",
            "Input: a(t) mod t^{2^n} = Σ_{i=0}^{2^n−1} a_i t^i, a₀ ≠ 0",
        ),
        (
            r"Output: \$`x\^\{\(n\)\}\(t\) = a\(t\)\^\{-1\} \\bmod t\^\{2\^n\}`\$",
            "Output: x^(n)(t) = a(t)^{−1} mod t^{2^n}",
        ),
    ]
    for pattern, repl in replacements:
        text = re.sub(pattern, repl, text)
    return text


def fix_prose_math(text: str) -> str:
    text = re.sub(
        r"\\mathrm\{sum\}\(i=0, N-1, a_\{i\} \\cdot x\^i\)",
        r"\\sum_{i=0}^{N-1} a_i x^i",
        text,
    )
    text = re.sub(
        r"\\mathrm\{sum\}\(i=0, N-1, a_\{i\} x\^i\)",
        r"\\sum_{i=0}^{N-1} a_i x^i",
        text,
    )
    text = re.sub(
        r"\\mathrm\{sum\}\(i=0, 2\^n-1, a_\{i\} t\^i\)",
        r"\\sum_{i=0}^{2^n-1} a_i t^i",
        text,
    )
    text = text.replace(r"**FFI**(N, B, \omega)", "**FFI**(N, B, ω)")
    text = text.replace(r"**FFT**(`(N, a(x), \omega, A)`)", "**FFT**(N, a(x), ω, A)")
    text = re.sub(
        r"\*\*([A-Z]+)\*\*\(`\(([^)]+)\)`\)",
        r"**\1**(\2)",
        text,
    )
    return text


def main() -> None:
    lines = MD.read_text().splitlines()
    head = "\n".join(lines[: START_LINE - 1])
    tail = "\n".join(lines[START_LINE - 1 :])

    tail = fix_algo_signatures(tail)
    tail = fix_prose_math(tail)
    tail = remath_all_tables(tail)
    tail = demath_simple_inline(tail)
    tail = convert_math_fences(tail)

    MD.write_text(head + "\n" + tail + "\n")
    print(f"Updated {MD} from line {START_LINE}")


if __name__ == "__main__":
    main()
