#!/usr/bin/env python3
"""Fix Courant_Ericson_1986.md math for GitHub-flavored MathJax preview."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MD = ROOT / "Courant_Ericson_1986.md"

ODIV = r"\mathbin{⨸}"
MATH_BLOCK = re.compile(r"\$\$(.*?)\$\$", re.DOTALL)
ICON_LEN = re.compile(r"(?<!\\texttt\{)\*([A-Za-z_][A-Za-z0-9_.]*)")


def fix_math_block(body: str) -> str:
    body = body.replace(r"\def\odiv{\mathbin{⨸}}", "")
    body = body.replace(r"\odiv", ODIV)

    # Icon length operator (#ad in source, *ad in algorithms).
    body = re.sub(r"\\#([A-Za-z_][A-Za-z0-9_.]*)", r"\\texttt{*}\1", body)
    body = body.replace(r"\#\ a", r"\text{\# a}")
    body = re.sub(r"\\#\s+", r"\\text{\\# }", body)
    body = ICON_LEN.sub(r"\\texttt{*}\1", body)

    # Hash string literals.
    body = body.replace(r'\text{"\#\#■"}', r'\texttt{"##■"}')
    body = body.replace(r'\text{"\#\#"}', r'\texttt{"##"}')
    body = body.replace(r'\text{"\#"}', r'\texttt{"#"}')

    # Icon list-append and string-concat operators.
    body = body.replace(r" \ |||{:=}\ ", r" \mathrel{\texttt{|||}{:=}} \ ")
    body = body.replace(r" \ ||| \ ", r" \mathrel{\texttt{|||}} \ ")
    body = body.replace(r"\,\|\,", r"\mathrel{\texttt{||}}")
    body = body.replace(r"\,\|\|", r"\mathrel{\texttt{||}}")
    body = re.sub(r" \|\| ", r" \\mathrel{\\texttt{||}} ", body)

    return body


def fix_inline_math(body: str) -> str:
    return body.replace(r"\odiv", ODIV)


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

    def repl_display(m: re.Match[str]) -> str:
        return "$$" + fix_math_block(m.group(1)) + "$$"

    text = MATH_BLOCK.sub(repl_display, text)

    def repl_inline(m: re.Match[str]) -> str:
        return "$" + fix_inline_math(m.group(1)) + "$"

    text = re.sub(r"(?<!\$)\$(?!\$)(.+?)(?<!\$)\$(?!\$)", repl_inline, text)
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
