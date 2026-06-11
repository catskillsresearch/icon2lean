#!/usr/bin/env python3
"""Extract Icon procedures and tests from Courant_Ericson_1986.md."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MD = ROOT / "Courant_Ericson_1986.md"
OUT_CODE = ROOT / "code.icon"
OUT_TESTS = ROOT / "tests.icon"
OUT_MANIFEST = ROOT / "tests_manifest.json"
OUT_COMPARE = ROOT / "compare_tests.py"

APPENDIX_MARK = "## Appendix"
SECTION_3_MARK = "## 3. Algorithms"


@dataclass
class IconBlock:
    line: int
    end_line: int
    body: str
    context: str = ""
    is_test: bool = False
    expected: list[str] = field(default_factory=list)


def extract_icon_blocks(text: str) -> list[IconBlock]:
    blocks: list[IconBlock] = []
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        if lines[i].strip() != "```icon":
            i += 1
            continue
        start = i + 1
        i += 1
        body_lines: list[str] = []
        while i < len(lines) and lines[i].strip() != "```":
            body_lines.append(lines[i])
            i += 1
        body = "\n".join(body_lines).strip("\n")
        end_line = i
        if not body:
            i += 1
            continue
        ctx_start = max(0, start - 8)
        context = "\n".join(lines[ctx_start:start])
        blocks.append(IconBlock(line=start, end_line=end_line, body=body, context=context))
        i += 1
    return blocks


def expectations_after_block(lines: list[str], end_line: int) -> list[str]:
    """Documented outputs in the lines following a test icon block."""
    expects: list[str] = []
    past_is = False
    for line in lines[end_line : end_line + 35]:
        t = line.strip()
        if t == "```icon":
            break
        if re.match(r"^is\s*$", t, re.I):
            past_is = True
            continue
        if t.startswith("$$") and t.endswith("$$"):
            expects.append(strip_math(t[2:-2]))
            continue
        if past_is and t and not t.startswith("<") and not t.startswith("**") and not t.startswith("|"):
            if re.search(r"#\d+#", t) or re.search(r"^[0-9\-(\[]", t):
                expects.append(strip_math(t))
            elif "mod " in t or " = " in t:
                expects.append(strip_math(t))
        for m in re.finditer(r"\$\$([^$]+)\$\$", t):
            expects.append(strip_math(m.group(1)))
        for m in re.finditer(r"\$([^$`][^$]*)\$", t):
            val = strip_math(m.group(1))
            if val and len(val) > 3:
                expects.append(val)
    # de-dupe preserving order
    seen: set[str] = set()
    out: list[str] = []
    for e in expects:
        e = normalize_expect(e)
        if e and e not in seen:
            seen.add(e)
            out.append(e)
    return out


def normalize_expect(s: str) -> str:
    s = re.sub(r"\s+", " ", s.strip())
    s = s.replace("\\cdot", "·").replace("\\bmod", "mod")
    return s


def fix_artifacts(s: str) -> str:
    s = re.sub(r'"([^"]*)"\}\s*,?\s*type\(', r'"\1" || type(', s)
    s = re.sub(r'mathbf\{0\}', 'zero', s)
    s = re.sub(r'mathbf\{1\}', 'one', s)
    s = re.sub(r'mathcal\{Q\}', 'Q', s)
    s = re.sub(r'mathcal\{Z\}', 'Z', s)
    s = re.sub(r'textit\{(\w+)\}', r'\1', s)
    s = re.sub(r'mathit\{unit\},?', 'unit', s)
    s = re.sub(r'mathit\{circleslash\}', 'odiv', s)
    s = re.sub(r'\bprs,', 'prs', s)
    s = re.sub(r'\bpr,', 'pr', s)
    s = re.sub(r'\bprint,', 'print', s)
    s = re.sub(r'\\_', '_', s)
    s = re.sub(r'\blacksquare\b', '■', s)
    s = re.sub(r'\s*≠q\s*', ' != ', s)
    s = re.sub(r'\s*bmod\s*', ' mod ', s)
    s = re.sub(r'type\(x\)\s*"', 'type(x) == "', s)
    return s


def unmathify_operators(s: str) -> str:
    # Domain-suffixed operators first
    for sym, name in (("⊕", "plus"), ("⊖", "ominus"), ("⊗", "times"), ("⨸", "div")):
        s = re.sub(rf"{re.escape(sym)}_([\w]+)", rf"{name}_\1", s)
        s = s.replace(sym, name)
    # Fancy predicates / ops with leading symbol
    s = re.sub(r"<_([\w]+)", r"less_\1", s)
    s = re.sub(r"=_([\w]+)", r"equal_\1", s)
    s = re.sub(r"=_(\w)", r"equal_\1", s)
    s = re.sub(r"-_([\w]+)", r"minus_\1", s)
    s = re.sub(r"<_degree", "less_degree", s)
    s = re.sub(r"=_poly", "equal_poly", s)
    s = re.sub(r"=_terms", "equal_terms", s)
    s = re.sub(r"=_term", "equal_term", s)
    s = re.sub(r"=_Q", "equal_Q", s)
    s = re.sub(r"=_Z", "equal_Z", s)
    s = re.sub(r"=_modulo", "equal_modulo", s)
    s = re.sub(r"=_digits", "equal_digits", s)
    s = re.sub(r"=_base_B", "equal_base_B", s)
    s = re.sub(r"\)\s*<0\(", ") & negative(", s)
    s = re.sub(r"<0\(", "negative(", s)
    s = re.sub(r"<0_([\w]+)", r"negative_\1", s)
    s = re.sub(r"=0_([\w]+)", r"is_zero_\1", s)
    # Typed zero/one constants: 0_poly(x) -> zero_poly(x)
    s = re.sub(r"\b0_([\w]+)\(", r"zero_\1(", s)
    s = re.sub(r"\b1_([\w]+)\(", r"one_\1(", s)
    s = re.sub(r"(?<!=)\b0\(", "zero(", s)
    s = re.sub(r"\b1\(", "one(", s)
    s = re.sub(r"\|\|:=", "|||:=", s)
    s = re.sub(r"\|\| \|:=", "|||:=", s)
    s = re.sub(r"\|\|\| :=", "|||:=", s)
    # divisibility |(g, bb)
    s = re.sub(r"\|\(([^)]+)\)", r"divides(\1)", s)
    return s


def unmathify_control(s: str) -> str:
    s = s.replace("⊥", "fail")
    s = re.sub(r"\s*■\s*$", "", s)
    s = re.sub(r"↑\s*", "return ", s)
    return s


PROC_LINE = re.compile(
    r"^([\w]+(?:_\w+)*|plus(?:_\w+)?|minus(?:_\w+)?|times(?:_\w+)?|div(?:_\w+)?|"
    r"equal(?:_\w+)?|less(?:_\w+)?|negative(?:_\w+)?|is_zero(?:_\w+)?|"
    r"normalize(?:_\w+)?|print(?:_\w+)?|mod(?:_\w+)?|Abs|exp|rem|unit|prs|pr|record)\s*"
    r"(\([^)]*\))?\s*←(.*)$",
    re.I,
)


def split_procedure_chunks(body: str) -> list[str]:
    body = fix_artifacts(body)
    if "■" in body:
        return [c.strip() for c in re.split(r"\s*■\s*", body) if c.strip()]
    return [body.strip()] if body.strip() else []


def chunk_has_procedure_arrow(chunk: str) -> bool:
    return "←" in chunk


def is_test_block(body: str, context: str) -> bool:
    if "Appendix" in context:
        return False
    if body.strip().startswith("procedure FFT"):
        return True
    if "settime(" in body or "showtime(" in body:
        return True
    # Blocks with procedure arrows (even if they mention pr{ for errors) are code.
    if chunk_has_procedure_arrow(body):
        return False
    if re.search(r"\bpr\{", body):
        return True
    if "**Example.**" in context and ":=" in body:
        return True
    return False


def parse_header(first_u: str) -> tuple[str, str, str] | None:
    """Return (name, params, rest-of-first-line) or None."""
    if first_u.startswith("record "):
        return None
    patterns: list[tuple[str, str]] = [
        (r"^\{\|\}\s*(\([^)]*\))\s*←(.*)$", "divides"),
        (r"^<\s*(\([^)]*\))\s*←(.*)$", "less"),
        (r"^=\s*(\([^)]*\))\s*←(.*)$", "equal"),
        (r"^<0\s*(\([^)]*\))\s*←(.*)$", "negative"),
        (r"^=0\s*(\([^)]*\))\s*←(.*)$", "is_zero"),
        (r"^-\s*(\([^)]*\))\s*←(.*)$", "minus"),
        (r"^([A-Za-z_][\w]*)\s*(\([^)]*\))\s*←(.*)$", r"\1"),
    ]
    for pat, name in patterns:
        m = re.match(pat, first_u)
        if m:
            if name == r"\1":
                return m.group(1), m.group(2), m.group(3).strip()
            return name, m.group(1), m.group(2).strip()
    return None


def procedure_name_from_chunk(chunk: str) -> str:
    first = unmathify_operators(fix_artifacts(chunk.splitlines()[0].strip()))
    m = re.match(r"^record\s+(\w+)", first)
    if m:
        return f"record_{m.group(1)}"
    parsed = parse_header(first)
    return parsed[0] if parsed else "anon"


def convert_to_icon_procedure(chunk: str) -> str:
    chunk = fix_artifacts(chunk)
    first = chunk.splitlines()[0].strip()
    first_u = unmathify_operators(first)

    if first_u.startswith("record "):
        rest = "\n".join(chunk.splitlines()[1:])
        lines_out = [first_u.replace("←", "").strip()]
        for raw in rest.splitlines():
            line = convert_body_line(raw)
            if line:
                lines_out.append("  " + line)
        return "\n".join(lines_out)

    parsed = parse_header(first_u)
    if not parsed:
        return "\n".join(convert_body_line(l) for l in chunk.splitlines() if l.strip())
    pname, params, same_line = parsed

    lines_out = [f"procedure {pname}{params}"]
    if same_line:
        lines_out.append("  " + convert_body_line(same_line))
    for raw in chunk.splitlines()[1:]:
        line = convert_body_line(raw)
        if line:
            lines_out.append("  " + line)
    lines_out.append("end")
    return "\n".join(lines_out)


def convert_body_line(raw: str) -> str:
    line = raw.rstrip()
    if not line.strip() or line.strip() == "■":
        return ""
    line = unmathify_operators(fix_artifacts(line))
    line = re.sub(r"(?<![\w<])<\(", "less(", line)
    line = re.sub(r"(?<![\w=:])=\(", "equal(", line)
    line = re.sub(r"=0\(", "is_zero(", line)
    line = re.sub(r"^(\s*)([\w]+(?:_\w+)*)\s*(\([^)]*\))?\s*←\s*", r"\1\2\3 := ", line)
    line = unmathify_control(line)
    line = line.replace("←", " := ")
    line = re.sub(r"return\s+return", "return", line)
    return line.strip()


def convert_test_body(body: str) -> str:
    body = fix_artifacts(body)
    lines = []
    for raw in body.splitlines():
        line = unmathify_operators(fix_artifacts(raw))
        line = unmathify_control(line)
        line = line.replace("←", " := ")
        if line.strip():
            lines.append(line)
    return "\n".join(lines)


def strip_math(s: str) -> str:
    s = re.sub(r"\$`([^`]+)`\$", r"\1", s)
    s = re.sub(r"\$\$([^$]+)\$\$", r"\1", s)
    s = s.replace("\\cdot", "·").replace("\\bmod", "mod")
    return s.strip()


def extract_table_tests(text: str) -> list[dict]:
    tests: list[dict] = []
    section = ""
    in_section_3 = False
    for line in text.splitlines():
        if line.startswith(SECTION_3_MARK):
            in_section_3 = True
        if line.startswith("## ") and SECTION_3_MARK not in line and in_section_3:
            if line.startswith("## 4") or "Appendix" in line:
                in_section_3 = False
        if line.startswith("###"):
            section = line.strip()
        if not in_section_3:
            continue
        if not line.strip().startswith("|") or "|:--" in line:
            continue
        cells = [c.strip() for c in line.split("|")[1:-1]]
        if len(cells) < 2 or cells[0].startswith("**"):
            continue
        tests.append(
            {
                "kind": "table",
                "section": section,
                "cells": [strip_math(c) for c in cells],
                "raw": line.strip(),
            }
        )
    return tests


def extract_prose_expectations(text: str) -> list[dict]:
    tests: list[dict] = []
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if "**Example.**" not in line:
            continue
        chunk = "\n".join(lines[i : i + 15])
        # output after "is" or "will print"
        for m in re.finditer(
            r"(?:is|prints? the following result:?|as obtained by evaluating)\s*\n+\s*(`[^`]+`|[^\n]+)",
            chunk,
            re.I,
        ):
            tests.append({"kind": "prose", "expected": strip_math(m.group(1).strip("`"))})
        for m in re.finditer(r"^\$\$([^$]+)\$\$", chunk, re.M):
            tests.append({"kind": "display_math", "expected": strip_math(m.group(1))})
        for m in re.finditer(r"^\[(\d+)\s*msecs\]", chunk, re.M):
            tests.append({"kind": "timing", "expected_ms": int(m.group(1))})
        for m in re.finditer(
            r"CRA\d?\([^)]+\):\s*`?x`?\s+such that\s+(.+?)\s+is\s+(\d+)",
            chunk,
        ):
            tests.append(
                {
                    "kind": "cra_bullet",
                    "constraint": strip_math(m.group(1)),
                    "expected": m.group(2),
                }
            )
        for m in re.finditer(r"no\s+`?x`?\s+such that\s+(.+)", chunk):
            tests.append({"kind": "cra_unsat", "constraint": strip_math(m.group(1))})
    return tests


def main() -> None:
    text = MD.read_text()
    appendix_pos = text.find(APPENDIX_MARK)
    core_text = text[:appendix_pos] if appendix_pos > 0 else text

    md_lines = core_text.splitlines()
    blocks = extract_icon_blocks(core_text)
    procedures: list[str] = []
    tests: list[str] = []
    proc_names: list[str] = []
    test_cases: list[dict] = []

    for blk in blocks:
        if is_test_block(blk.body, blk.context):
            converted = convert_test_body(blk.body)
            expects = expectations_after_block(md_lines, blk.end_line)
            tests.append(f"# --- test near md line {blk.line} ---")
            for exp in expects:
                tests.append(f"# EXPECT: {exp}")
            tests.append(converted)
            tests.append("")
            test_cases.append(
                {"md_line": blk.line, "body": converted, "expected": expects}
            )
            continue

        for chunk in split_procedure_chunks(blk.body):
            if not chunk_has_procedure_arrow(chunk):
                tests.append(f"# --- snippet line {blk.line} ---")
                tests.append(convert_test_body(chunk))
                tests.append("")
                continue
            name = procedure_name_from_chunk(chunk)
            if name in proc_names:
                name = f"{name}_{blk.line}"
            proc_names.append(name)
            procedures.append(f"# --- {name} (md line {blk.line}) ---")
            procedures.append(convert_to_icon_procedure(chunk))
            procedures.append("")

    table_tests = extract_table_tests(core_text)
    prose_tests = extract_prose_expectations(core_text)

    code_header = """# EUCLID package extracted from Courant_Ericson_1986.md
# Fancy notation un-mathified per Section 1.3.
# Link: link "code.icon"  (or include in your Icon program)

"""
    tests_header = """# Tests and examples from Courant_Ericson_1986.md
# Expected outputs are in # EXPECT: comments and tests_manifest.json
link "code.icon"

"""

    OUT_CODE.write_text(code_header + "\n".join(procedures))
    OUT_TESTS.write_text(tests_header + "\n".join(tests))

    lean_golden = {
        "euclidInt_84_54": "(6, 2, -3)",
        "cra2_6_7_3_9": "48",
        "cra_list": "868",
        "cra_poly_u": "238",
        "cra_poly_v": "183",
        "diophantine_84_54": "(1, -2)",
        "diophantine_999_49": "(13, 163)",
        "diophantine_247_589": "(-11, 6)",
        "prem_coeff_0": "198",
        "prem_coeff_1": "-225",
        "prem_coeff_2": "306",
    }
    manifest = {
        "source": str(MD.name),
        "procedure_count": len(proc_names),
        "procedures": proc_names,
        "icon_test_cases": test_cases,
        "table_tests": table_tests,
        "prose_tests": prose_tests,
        "lean_golden": lean_golden,
    }
    OUT_MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n")

    compare_py = COMPARE_TEMPLATE.format(
        manifest_path=OUT_MANIFEST.name,
    )
    OUT_COMPARE.write_text(compare_py)
    print(f"Wrote {OUT_CODE} ({len(proc_names)} procedures)")
    print(f"Wrote {OUT_TESTS}")
    print(f"Wrote {OUT_MANIFEST} ({len(table_tests)} table + {len(prose_tests)} prose tests)")
    print(f"Wrote {OUT_COMPARE}")


COMPARE_TEMPLATE = '''#!/usr/bin/env python3
"""Compare Icon test output against expectations in tests_manifest.json."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MANIFEST = ROOT / "{manifest_path}"
TESTS_ICON = ROOT / "tests.icon"
CODE_ICON = ROOT / "code.icon"


def load_manifest() -> dict:
    return json.loads(MANIFEST.read_text())


def run_icon(test_file: Path) -> tuple[int, str, str]:
    """Run tests.icon with Icon if available."""
    for cmd in (["icon", str(test_file)], ["/usr/bin/icon", str(test_file)]):
        try:
            p = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=120,
                cwd=ROOT,
            )
            return p.returncode, p.stdout, p.stderr
        except FileNotFoundError:
            continue
    return -1, "", "icon interpreter not found"


def check_manifest(manifest: dict) -> list[str]:
    """Static checks without Icon: verify manifest structure."""
    issues: list[str] = []
    if not CODE_ICON.exists():
        issues.append(f"missing {{CODE_ICON}}")
    if not TESTS_ICON.exists():
        issues.append(f"missing {{TESTS_ICON}}")
    procs = manifest.get("procedures", [])
    if len(procs) < 50:
        issues.append(f"only {{len(procs)}} procedures in manifest (expected ~100+)")
    for t in manifest.get("table_tests", []):
        if not t.get("cells"):
            issues.append(f"empty table test: {{t}}")
    return issues


def extract_expect_comments(tests_text: str) -> list[str]:
    return [
        line[len("# EXPECT:") :].strip()
        for line in tests_text.splitlines()
        if line.strip().startswith("# EXPECT:")
    ]


def normalize(s: str) -> str:
    s = re.sub(r"\\s+", " ", s.strip())
    return s


def compare_output_to_expectations(stdout: str, manifest: dict, expect_comments: list[str]) -> list[str]:
    failures: list[str] = []
    out = normalize(stdout)
    for exp in expect_comments:
        if exp and normalize(exp) not in out:
            failures.append(f"stdout missing EXPECT comment: {{exp[:80]}}")
    for case in manifest.get("icon_test_cases", []):
        for exp in case.get("expected", []):
            if exp and normalize(exp) not in out:
                failures.append(f"manifest test line {{case.get('md_line')}}: missing {{exp[:60]}}")
    for t in manifest.get("prose_tests", []):
        if t.get("kind") == "display_math":
            frag = normalize(t.get("expected", ""))[:40]
            if frag and frag not in out:
                failures.append(f"prose expected fragment not in output: {{frag}}")
    return failures


def report_manifest_coverage(manifest: dict) -> None:
  """Print summary of documented expectations (no Icon required)."""
  n_icon = sum(len(c.get("expected", [])) for c in manifest.get("icon_test_cases", []))
  n_table = len(manifest.get("table_tests", []))
  n_prose = len(manifest.get("prose_tests", []))
  n_lean = len(manifest.get("lean_golden", {{}}))
  print(f"Documented expectations: {{n_icon}} icon-test, {{n_table}} table rows, "
        f"{{n_prose}} prose, {{n_lean}} lean golden values")


def main() -> int:
    manifest = load_manifest()
    issues = check_manifest(manifest)
    tests_text = TESTS_ICON.read_text() if TESTS_ICON.exists() else ""
    expect_comments = extract_expect_comments(tests_text)

    report_manifest_coverage(manifest)
    print(f"Manifest: {{len(manifest.get('procedures', []))}} procedures")

    rc, stdout, stderr = run_icon(TESTS_ICON)
    if rc == -1:
        print("NOTE: Icon not installed; running static checks only.")
        print("Static issues:", issues or "none")
        print(f"# EXPECT comments in tests.icon: {{len(expect_comments)}}")
        missing = []
        for case in manifest.get("icon_test_cases", []):
            if not case.get("expected"):
                missing.append(case.get("md_line"))
        if missing:
            print(f"Test blocks without extracted expectations (md lines): {{missing[:10]}}")
        return 0 if not issues else 1

    print("--- stdout ---")
    print(stdout)
    if stderr:
        print("--- stderr ---", file=sys.stderr)
        print(stderr, file=sys.stderr)

    failures = issues + compare_output_to_expectations(stdout, manifest, expect_comments)
    if failures:
        print("FAILURES:")
        for f in failures:
            print(" ", f)
        return 1
    print("All checks passed.")
    return 0 if rc == 0 else rc


if __name__ == "__main__":
    sys.exit(main())
'''


if __name__ == "__main__":
    main()
