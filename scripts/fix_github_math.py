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


def split_underscores_out_of_text(body: str) -> str:
    """GitHub breaks on _ inside \\text{}; keep underscores in math mode via \\_."""

    def repl(match: re.Match[str]) -> str:
        content = match.group(1)
        if "_" not in content:
            return match.group(0)

        qtrail = re.fullmatch(r'"([^"]*)_"', content)
        if qtrail:
            inner = qtrail.group(1)
            if "_" in inner:
                sub = inner.split("_")
                out = r'\text{"' + sub[0] + '"}'
                for sp in sub[1:]:
                    out += r'\_\text{"' + sp + '"}'
                out += r'\_\text{""}'
                return out
            return r'\text{"' + inner + r'"}\_\text{""}'

        qsingle = re.fullmatch(r"'([^']*)'", content)
        if qsingle:
            inner = qsingle.group(1)
            if inner.startswith("_"):
                return "\\text{'\\}\\_\\text{'" + inner[1:] + "'}"
            if "_" in inner:
                sub = inner.split("_")
                out = r"\text{'" + sub[0] + "'}"
                for sp in sub[1:]:
                    out += r"\_\text{'" + sp + "'}"
                return out

        if r"\_" in content:
            return match.group(0)
        parts = content.split("_")
        out = r"\text{" + parts[0] + "}"
        for part in parts[1:]:
            out += r"\_\text{" + part + "}"
        return out

    prev = None
    while prev != body:
        prev = body
        body = re.sub(r"\\text\{([^{}]*)\}", repl, body)
    return body


def tidy_math_identifiers(body: str) -> str:
    return re.sub(r"\\_ +", r"\\_", body)


def fix_github_operators(body: str) -> str:
    body = body.replace(r"\mathrel{\sim=}", r"\neq")
    body = body.replace(r"\mathbin{\%}", r"\bmod")
    return body


def fix_underscore_joins(body: str) -> str:
    """Inside $$ blocks only; prefer ```math fences (see convert_math_fences.py)."""
    return body.replace(r"\_\text{", r"\mathord{\texttt{\_}}\text{")


def escape_hash_in_texttt(body: str) -> str:
    def repl(m: re.Match[str]) -> str:
        inner = re.sub(r"(?<!\\)#", r"\\#", m.group(1))
        return r"\texttt{" + inner + "}"

    prev = None
    while prev != body:
        prev = body
        body = re.sub(r"\\texttt\{([^{}]*)\}", repl, body)
    return body


def escape_text_underscores(body: str) -> str:
    def repl(m: re.Match[str]) -> str:
        inner = re.sub(r"(?<!\\)_", r"\\_", m.group(1))
        return r"\text{" + inner + "}"

    prev = None
    while prev != body:
        prev = body
        body = re.sub(r"\\text\{([^{}]*)\}", repl, body)
    return body


def fix_underscores(body: str) -> str:
    """No bare _ inside \\text{}; Icon names use \\_ in math mode."""
    body = body.replace(r"\textunderscore", r"\_")
    body = escape_text_underscores(body)
    body = fix_underscore_joins(body)
    body = tidy_math_identifiers(body)
    return body


def fix_github_algorithm_operators(body: str) -> str:
    body = re.sub(r"\\mathop\{([<=-])\}_\{([^}]+)\}", r"\1_{\2}", body)
    body = re.sub(r"^&([<=-])_", r"&{\1}_", body, flags=re.MULTILINE)
    body = re.sub(r"(?<!\\text\{)type\(([^)]+)\)", r"\\text{type}(\1)", body)
    body = body.replace(
        r'\text{type}(a) \mathrel{=} \text{"string"}',
        r'\text{type}(a) \mathrel{==} \text{"string"}',
    )
    body = body.replace(
        r'\text{type}(b) \mathrel{=} \text{"string"}',
        r'\text{type}(b) \mathrel{==} \text{"string"}',
    )
    body = body.replace(r'\text{"- infinity"}', r"\text{- infinity}")
    body = body.replace(
        r"\mathrel{\texttt{|||}{:=}}", r"\mathrel{\texttt{|||}}\mathrel{:=}"
    )
    body = re.sub(r"^&\\\\\s*$", "", body, flags=re.MULTILINE)
    return body


def brace_bare_subscripts(s: str) -> str:
    """Brace _suffix at depth 0 so GitHub markdown does not treat _ as emphasis."""
    result: list[str] = []
    depth = 0
    i = 0
    while i < len(s):
        ch = s[i]
        escaped = i > 0 and s[i - 1] == "\\"
        if ch == "{" and not escaped:
            depth += 1
            result.append(ch)
            i += 1
        elif ch == "}" and not escaped:
            depth -= 1
            result.append(ch)
            i += 1
        elif ch == "_" and depth == 0 and not escaped:
            if i + 1 < len(s) and s[i + 1] == "{":
                result.append(ch)
                i += 1
                continue
            j = i + 1
            while j < len(s) and (s[j].isalnum() or s[j] == "_"):
                j += 1
            suffix = s[i + 1 : j]
            result.append("_{")
            result.append(suffix)
            result.append("}")
            i = j
        else:
            result.append(ch)
            i += 1
    return "".join(result)


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
    body = fix_github_operators(body)
    body = fix_underscores(body)
    body = escape_hash_in_texttt(body)
    body = fix_github_algorithm_operators(body)
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
    body = fix_underscores(body)
    return brace_bare_subscripts(body)


def fix_inline_math(text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        return "$" + fix_inline_math_body(match.group(1)) + "$"

    return re.sub(r"(?<!\$)\$(?!\$)(.+?)(?<!\$)\$(?!\$)", repl, text)


INLINE_MATH_DELIM = re.compile(r"(?<!\$)\$([^$\n]+?)\$(?!\$)")
MATH_FENCE_SPLIT = re.compile(r"(```math\n.*?\n```)", re.DOTALL)


def wrap_inline_math_delimiters(line: str) -> str:
    """GitHub: $`...`$ protects inline math from markdown/HTML parsing."""

    def repl(m: re.Match[str]) -> str:
        inner = m.group(1)
        if inner.startswith("`") and inner.endswith("`"):
            return m.group(0)
        return "$`" + inner + "`$"

    return INLINE_MATH_DELIM.sub(repl, line)


def fix_inline_math_delimiters(text: str) -> str:
    parts = MATH_FENCE_SPLIT.split(text)
    out: list[str] = []
    for part in parts:
        if part.startswith("```math"):
            out.append(part)
            continue
        lines: list[str] = []
        for line in part.splitlines(keepends=True):
            stripped = line.strip()
            if stripped.startswith("$$") and stripped.endswith("$$"):
                lines.append(line)
            else:
                lines.append(wrap_inline_math_delimiters(line))
        out.append("".join(lines))
    return "".join(out)


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
        'To test for the procedure $\\otimes_{Z}$, we evaluate `proc("times" || "_Z", 2)`, '
        'and in general, for some string value X which corresponds to a procedure name, '
        'Y a domain name, and i a number of formal parameters, we evaluate '
        '`proc(X || "_" || Y, i)`, where `||` is the ICON string concatenation operator.',
    )
    text = text.replace('underscore ("_")', 'underscore (`"_"`)')
    text = text.replace("in the 10000^ range.", "in the `10000^4` range.")
    text = text.replace(
        'the string "$`-\\infty`$"',
        'the string `"- infinity"`',
    )
    text = text.replace(
        'the string "$-\\infty$"',
        'the string `"- infinity"`',
    )
    return text


MATH_FENCE = re.compile(r"```math\n(.*?)\n```", re.DOTALL)


def fix_math_fence_blocks(text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        body = normalize_math_body(match.group(1))
        return "```math\n" + body + "\n```"

    return MATH_FENCE.sub(repl, text)


def fix_github_math(text: str) -> str:
    text = fix_prose(text)
    text = fix_math_left_blocks(text)
    text = fix_math_fence_blocks(text)
    text = fix_display_math(text)
    text = fix_inline_math(text)
    text = fix_inline_math_delimiters(text)
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
