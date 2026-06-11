#!/usr/bin/env python3
"""Fix Courant_Ericson_1986.md math for GitHub MathJax without breaking VS Code/KaTeX."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MD = ROOT / "Courant_Ericson_1986.md"

ODIV = r"\mathbin{⨸}"
MATH_BLOCK = re.compile(r"\$\$(.*?)\$\$", re.DOTALL)
MATH_LEFT = re.compile(
    r'(<div class="math-left">\s*\n+\s*\$\$\s*\n)(.*?)(\n\$\$\s*\n\s*</div>)',
    re.DOTALL,
)
ICON_LEN = re.compile(r"(?<!\\texttt\{)\*([A-Za-z_][A-Za-z0-9_.]*)")
ARRAY_L = re.compile(r"\\begin\{array\}\{l\}(.*?)\\end\{array\}", re.DOTALL)


def fix_underscores(body: str) -> str:
    """GitHub markdown eats \\_ before MathJax; \\textunderscore works everywhere."""
    body = body.replace(r"\_", r"\textunderscore")
    # Tighten string literals: "div\textunderscore " -> "div\textunderscore"
    body = re.sub(r"\\textunderscore\s+([\"'])", r"\\textunderscore\1", body)
    return body


def fix_math_operators(body: str) -> str:
    body = body.replace(r"\def\odiv{\mathbin{⨸}}", "")
    body = body.replace(r"\odiv", ODIV)

    body = re.sub(r"\\#([A-Za-z_][A-Za-z0-9_.]*)", r"\\texttt{*}\1", body)
    body = body.replace(r"\#\ a", r"\text{\# a}")
    body = re.sub(r"\\#\s+", r"\\text{\\# }", body)
    body = ICON_LEN.sub(r"\\texttt{*}\1", body)

    body = body.replace(r'\text{"\#\#■"}', r'\texttt{"##■"}')
    body = body.replace(r'\text{"\#\#"}', r'\texttt{"##"}')
    body = body.replace(r'\text{"\#"}', r'\texttt{"#"}')

    body = body.replace(r" \ |||{:=}\ ", r" \mathrel{\texttt{|||}{:=}} \ ")
    body = body.replace(r" \ ||| \ ", r" \mathrel{\texttt{|||}} \ ")
    body = body.replace(r"\,\|\,", r"\mathrel{\texttt{||}}")
    body = body.replace(r"\,\|\|", r"\mathrel{\texttt{||}}")
    body = re.sub(r" \|\| ", r" \\mathrel{\\texttt{||}} ", body)
    return body


def prefix_aligned_line(line: str) -> str:
    stripped = line.strip()
    if not stripped:
        return line
    if stripped.startswith("&"):
        return line
    match = re.match(r"^(\s*)(.*)$", line)
    if not match:
        return line
    indent, rest = match.groups()
    return f"{indent}&{rest}"


def array_to_aligned(body: str) -> str:
    def repl(match: re.Match[str]) -> str:
        inner = match.group(1)
        lines = re.split(r"\n", inner)
        out: list[str] = []
        for line in lines:
            out.append(prefix_aligned_line(line))
        return r"\begin{aligned}" + "\n" + "\n".join(out) + "\n" + r"\end{aligned}"

    return ARRAY_L.sub(repl, body)


def wrap_single_line_aligned(body: str) -> str:
    stripped = body.strip()
    if not stripped:
        return body
    if r"\begin{aligned}" in stripped or r"\begin{array}" in stripped:
        return stripped
    if r"\begin{" in stripped:
        return stripped
    return r"\begin{aligned}" + "\n&" + stripped + "\n" + r"\end{aligned}"


def normalize_math_body(body: str) -> str:
    body = body.strip("\n")
    # GitHub treats blank lines inside $$ as ending the math block.
    body = re.sub(r"\n{3,}", "\n\n", body)
    body = re.sub(r"(\\begin\{aligned\})\n\n+", r"\1\n", body)
    body = re.sub(r"\n\n+(\\end\{aligned\})", r"\n\1", body)
    body = fix_math_operators(body)
    body = fix_underscores(body)
    body = array_to_aligned(body)
    return body


def fix_math_left_blocks(text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        prefix, body, suffix = match.groups()
        fixed = wrap_single_line_aligned(normalize_math_body(body))
        return prefix + fixed + suffix

    return MATH_LEFT.sub(repl, text)


def fix_display_math(text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        return "$$" + normalize_math_body(match.group(1)) + "$$"

    return MATH_BLOCK.sub(repl, text)


def fix_inline_math_body(body: str) -> str:
    body = body.replace(r"\odiv", ODIV)
    return fix_underscores(body)


def fix_inline_math(text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        return "$" + fix_inline_math_body(match.group(1)) + "$"

    return re.sub(r"(?<!\$)\$(?!\$)(.+?)(?<!\$)\$(?!\$)", repl, text)


def fix_prose(text: str) -> str:
    text = text.replace('proc("X\', 3)', 'proc("X", 3)')
    text = text.replace(
        "proc('times\" `||` `\"_Z\"`, 2)",
        'proc("times" || "_Z", 2)',
    )
    text = text.replace('proc(X || `"_"` Y, i)', 'proc(X || "_" || Y, i)')
    text = text.replace('proc(X || "_" Y, i)', 'proc(X || "_" || Y, i)')
    text = text.replace(
        'To test for the procedure $\\otimes_Z$, we evaluate proc("times" || "_Z", 2), '
        'and in general, for some string value X which corresponds to a procedure name, '
        'Y a domain name, and i a number of formal parameters, we evaluate '
        'proc(X || "_" || Y, i), where || is the ICON string concatenation operator.',
        'To test for the procedure $\\otimes_Z$, we evaluate `proc("times" || "_Z", 2)`, '
        'and in general, for some string value X which corresponds to a procedure name, '
        'Y a domain name, and i a number of formal parameters, we evaluate '
        '`proc(X || "_" || Y, i)`, where `||` is the ICON string concatenation operator.',
    )
    text = text.replace('underscore ("_")', 'underscore (`"_"`)')
    text = text.replace("in the 10000^ range.", "in the `10000^4` range.")
    return text


def fix_github_math(text: str) -> str:
    text = fix_prose(text)
    text = fix_math_left_blocks(text)
    text = fix_display_math(text)
    text = fix_inline_math(text)
    return text


def main() -> None:
    original = MD.read_text(encoding="utf-8")
    fixed = fix_github_math(original)
    if fixed != original:
        MD.write_text(fixed, encoding="utf-8")
        print(f"Updated {MD}")
    else:
        print("No changes needed")


if __name__ == "__main__":
    main()
