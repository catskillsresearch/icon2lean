#!/usr/bin/env python3
"""Convert extracted Courant/Ericson 1986 PDF text to Markdown with Icon code blocks."""

import re
import sys
from pathlib import Path

TITLE = "An ICON Package for Experimenting with Euclidean Domains"
AUTHOR = "Lars Warren Ericson"
REPORT = "NYU Computer Science Technical Report #232"
DATE = "August 1986"

SKIP_RES = [
    re.compile(r"^\s*\d+\s*$"),
    re.compile(r"^An ICON package for experimenting", re.I),
    re.compile(r"^Introduction\s*$"),
    re.compile(r"^Euclidean domains:", re.I),
    re.compile(r"^Algorithms for", re.I),
    re.compile(r"^Appendix\.", re.I),
    re.compile(r"^Computer Science Department\s*$"),
    re.compile(r"^TECHNICAL REPORT\s*$"),
    re.compile(r"^NEW YORK UNIVERSITY\s*$"),
    re.compile(r"^Courant Institute", re.I),
    re.compile(r"^Department of Computer Science\s*$"),
    re.compile(r"^Contents\s*$"),
    re.compile(r"^References\s*$"),
    re.compile(r"^Abstract\s*$"),
    re.compile(r"^►"),
    re.compile(r"^J Department of Computer Science"),
    re.compile(r"^; 1 251 MERCER"),
    re.compile(r"^May 16, 1986\s*$"),
    re.compile(r"^ARPA:"),
    re.compile(r"^251 Mercer"),
    re.compile(r"^New York University\s*$"),
    re.compile(r"^Lars Warren Ericson\s*$"),
    re.compile(r"^by\s*$"),
    re.compile(r"^August, 1986\s*$"),
    re.compile(r"^’Technical Report"),
    re.compile(r"^\"An ICON Package"),
    re.compile(r"^Experimenting with Euclidean"),
    re.compile(r"^[CNMOHP\s\d\(\)\-\<\>\'\"\.]{0,40}$"),
    re.compile(r"^\.{3,}\s*\d+\s*$"),
]

SECTION_RE = re.compile(r"^(\d+(?:\.\d+)*)\.\s+(.+)$")
TOC_INLINE_RE = re.compile(r"\.{3,}\s*\d+")

PROSE_START_RE = re.compile(
    r"^(The |This |We |Our |For |In |When |A |An |According |Example\.|Input:|Output:|"
    r"John |Lipson|Supposing |As an |They |Niven |Let |Executing |yields |Note that|"
    r"Table |Data structures\.|Constants\.|Operators\.|Predicates\.|Commands\.|"
    r"Implementation|Primitive |The following |Given |Suppose |Returns |Assume |"
    r"Similarly |All of the |On top of |These are |Outputs |For printing |"
    r"Every |BASIC |Operator |Type |Required |Optional |Synthesized |Constant |"
    r"procedures\.|For a typical )",
    re.I,
)

STRONG_CODE_RE = re.compile(
    r"""^(
        record\s+\w|
        procedure\s+\w|
        global\s+\w|
        local\s+\w|
        for\s+\w|
        \w+\s*\([^)]*\)\s*(<=\s*|4=\s*)|
        \w+\s*(<=\s*|4=\s*)|
        proc\s*\(\s*\"|
        every\s+\w|
        repeat\s*$|
        while\s+\w|
        if\s*\(|if\s+\w|
        else\s*$|
        then\s*$|
        begin\s*$|
        end\s*$|
        write\s*\(|wrlte\s*\(|
        process\s*\(\s*\"|
        get_llne\s*\(|
        ##\s*#|
        #\s*#code|#\s*#end|
        .*\|\|\s*type\s*\(|
        .*\|\|\s*typ|
        ^[\{\[].*[\}\]]\s*$|
        ^[\{\[]\s*[^}]+\.\s*\}\s*$
    )""",
    re.VERBOSE | re.IGNORECASE,
)

WEAK_CODE_RE = re.compile(
    r"^(else|then|begin|end|repeat|break|fail|also)\s*$|■\s*$|^\s{2,}\S",
    re.I,
)

EXAMPLE_OUTPUT_RE = re.compile(
    r"^\s*(\d+\s*[#\^]|ERROR|\(\.\d|Extended Greatest|GCD,|\d+,\d+)"
)

OCR_JUNK_RE = re.compile(
    r"^[\s;:\.\-'\"^*!?\\|/\\<>©®]{0,3}[\w\s;:\.\-'\"^*!?\\|/\\<>©®]{0,40}$"
)


def skip_line(line: str) -> bool:
    s = line.strip()
    if not s:
        return False
    return any(p.search(s) for p in SKIP_RES)


def is_ocr_junk(line: str) -> bool:
    s = line.strip()
    if len(s) < 3:
        return True
    if re.match(r"^[\W_]+$", s):
        return True
    # Mostly punctuation / garbled short fragments
    alpha = sum(c.isalpha() for c in s)
    if len(s) < 25 and alpha < len(s) * 0.35:
        return True
    if re.search(r"(btinTfif|nnsnii|nf\)igtos|or:sm|\.nc')", s):
        return True
    return False


def is_toc_line(line: str) -> bool:
    return bool(TOC_INLINE_RE.search(line))


def parse_heading(line: str) -> tuple[int, str] | None:
    s = line.strip()
    if is_toc_line(s):
        return None
    m = SECTION_RE.match(s)
    if not m:
        return None
    num, title = m.group(1), m.group(2).strip()
    if len(title) < 3:
        return None
    depth = min(num.count(".") + 2, 4)
    return depth, f"{num}. {title}"


def looks_like_prose(line: str, *, in_code: bool = False) -> bool:
    s = line.strip()
    if not s:
        return False
    if in_code:
        # Inside code, only break on clear prose paragraphs
        if len(s) > 160:
            return True
        if PROSE_START_RE.match(s) and not s.startswith(("Input:", "Output:")):
            return True
        if s.count(". ") >= 2 and not s.startswith("{"):
            return True
        return False
    if len(s) > 130:
        return True
    if PROSE_START_RE.match(s):
        return True
    if s.count(". ") >= 2:
        return True
    if re.search(r"\[[A-Za-z]+\d", s):
        return True
    if re.match(r"^[•\-]\s", s):
        return True
    if re.search(r"[a-z]\.\s+[A-Z]", s):
        return True
    return False


def looks_like_code(line: str) -> bool:
    s = line.rstrip()
    if not s.strip() or is_ocr_junk(s):
        return False
    if looks_like_prose(s):
        return False
    if STRONG_CODE_RE.match(s.strip()):
        return True
    if WEAK_CODE_RE.match(s):
        return True
    stripped = s.strip()
    if stripped.endswith("■"):
        return True
    if "||" in stripped and ("type(" in stripped or "typ" in stripped):
        return True
    if re.match(r"^[\w©®\-+\*/\(\)\[\]\{\}\.,\"\'\|&;:=<> ]+$", stripped):
        if ":=" in stripped or "<=" in stripped or "4=" in stripped:
            return True
        if re.match(r"^[A-Z_]+\s*\(", stripped):
            return True
    return False


def find_content_start(lines: list[str]) -> int:
    for i, line in enumerate(lines):
        if re.match(r"^1\.\s+Introduction\s*$", line.strip()):
            return i
    return 0


def extract_abstract(lines: list[str], start: int) -> str:
    chunks: list[str] = []
    for line in lines[:start]:
        s = line.strip()
        if not s or skip_line(line) or is_toc_line(s):
            continue
        if re.search(r"\b1\.\s+Introduction\b", s) or TOC_INLINE_RE.search(s):
            break
        if re.match(r"^\d+\.\s+[A-Z]", s) and "..." in s:
            break
        if "understanding the algebraic algorithms" in s or chunks:
            if is_ocr_junk(s):
                continue
            chunks.append(s)
    return re.sub(r"\s+\d+\.\s+[A-Z][^.]*(?:\.{3,}|$).*$", "", " ".join(chunks)).strip()


def convert(lines: list[str]) -> str:
    start = find_content_start(lines)
    abstract = extract_abstract(lines, start)

    out: list[str] = [
        f"# {TITLE}",
        "",
        f"**Author:** {AUTHOR}  ",
        f"**Institution:** Courant Institute of Mathematical Sciences, New York University  ",
        f"**Report:** {REPORT}  ",
        f"**Date:** {DATE}",
        "",
        "> Transcription of the 1986 technical report from PDF. Icon listings use the "
        "report's *fancy notation* (see Section 1.3): e.g. `©` for division, `®` for "
        "addition, `F (a,b) <= code ■` for procedure definitions, and `))` for `return`. "
        "Some OCR artifacts from the scanned source may remain.",
        "",
    ]
    if abstract:
        out.extend(["## Abstract", "", abstract, "", "---", ""])

    i = start
    prose_buf: list[str] = []
    code_buf: list[str] = []
    in_code = False
    in_example = False

    def flush_prose():
        nonlocal prose_buf, in_example
        if not prose_buf:
            return
        text = " ".join(prose_buf)
        if in_example and EXAMPLE_OUTPUT_RE.match(text.strip()):
            out.append("```text")
            out.append(text.strip())
            out.append("```")
            out.append("")
            in_example = False
        else:
            emit_paragraph(prose_buf, out)
            if re.search(r"Example\.|result of evaluating|The following code:", text, re.I):
                in_example = True
        prose_buf = []

    def flush_code():
        nonlocal code_buf, in_code
        if code_buf:
            body = "\n".join(l for l in code_buf if not is_ocr_junk(l)).strip()
            if body:
                out.append("```icon")
                out.append(body)
                out.append("```")
                out.append("")
        code_buf = []
        in_code = False

    while i < len(lines):
        raw = lines[i].rstrip()
        i += 1

        if skip_line(raw) or is_ocr_junk(raw):
            continue

        if not raw.strip():
            if in_code:
                j = i
                while j < len(lines) and not lines[j].strip():
                    j += 1
                if j < len(lines) and not looks_like_prose(lines[j], in_code=True):
                    code_buf.append("")
                    continue
            flush_code()
            flush_prose()
            continue

        heading = parse_heading(raw)
        if heading:
            flush_code()
            flush_prose()
            depth, text = heading
            out.append("")
            out.append(f"{'#' * depth} {text}")
            out.append("")
            continue

        if in_code:
            if looks_like_prose(raw, in_code=True):
                flush_code()
                prose_buf.append(raw.strip())
            else:
                code_buf.append(raw)
            continue

        if looks_like_code(raw):
            flush_prose()
            in_code = True
            code_buf.append(raw)
            continue

        prose_buf.append(raw.strip())

    flush_code()
    flush_prose()

    md = "\n".join(out)
    md = re.sub(r"\n{4,}", "\n\n\n", md)
    return md.strip() + "\n"


def emit_paragraph(buf: list[str], out: list[str]) -> None:
    if buf:
        out.append(" ".join(buf))
        out.append("")


def main() -> int:
    src = Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp/mutool_full.txt")
    dst = Path(
        sys.argv[2]
        if len(sys.argv) > 2
        else str(Path(__file__).resolve().parents[1] / "Courant_Ericson_1986.md")
    )
    raw = src.read_text(encoding="utf-8", errors="replace")
    lines = raw.replace("\f", "\n").splitlines()
    md = convert(lines)
    dst.write_text(md, encoding="utf-8")
    blocks = md.count("```icon")
    print(f"Wrote {dst} ({len(md):,} bytes, {md.count(chr(10)):,} lines, {blocks} icon blocks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
