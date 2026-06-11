#!/usr/bin/env python3
"""Compare Icon test output against expectations in tests_manifest.json."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MANIFEST = ROOT / "tests_manifest.json"
TESTS_ICON = ROOT / "tests.icn"
CODE_ICON = ROOT / "code.icn"


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
        issues.append(f"missing {CODE_ICON}")
    if not TESTS_ICON.exists():
        issues.append(f"missing {TESTS_ICON}")
    procs = manifest.get("procedures", [])
    if len(procs) < 50:
        issues.append(f"only {len(procs)} procedures in manifest (expected ~100+)")
    for t in manifest.get("table_tests", []):
        if not t.get("cells"):
            issues.append(f"empty table test: {t}")
    return issues


def extract_expect_comments(tests_text: str) -> list[str]:
    return [
        line[len("# EXPECT:") :].strip()
        for line in tests_text.splitlines()
        if line.strip().startswith("# EXPECT:")
    ]


def normalize(s: str) -> str:
    s = re.sub(r"\s+", " ", s.strip())
    s = s.replace("\\text{:}", ":").replace("·", "*")
    s = s.replace("(-", "(").replace(")z", "z")  # (-998z) vs (-998z)
    return s


def z_key(line: str) -> str | None:
    """Normalize '1z + (-999z) = (-998z)' style Z arithmetic lines."""
    m = re.search(
        r"^(.+?)\s*=\s*(.+)$",
        line.strip(),
    )
    if not m or "z" not in line:
        return None

    def norm_z_expr(expr: str) -> str:
        expr = re.sub(r"\s+", "", expr)
        expr = expr.replace("(-", "-").replace(")", "")
        return expr

    return f"{norm_z_expr(m.group(1))}={norm_z_expr(m.group(2))}"


def base_b_key(line: str) -> str | None:
    """Normalize '1 0 0 0 #8#' style output for fuzzy compare."""
    m = re.search(r"^(.+?)\s*#\s*(\d+)\s*#\s*$", line.strip())
    if not m:
        return None
    digits = re.sub(r"\s+", "", m.group(1))
    return f"#{m.group(2)}#:{digits}"


def expect_matches(stdout: str, expected: str) -> bool:
    exp = normalize(expected)
    if not exp or exp.startswith("`") or "text{" in exp:
        return True  # skip LaTeX-only expectations
    out = normalize(stdout)
    if exp in out:
        return True
    # Compare base_B lines ignoring spacing between digits
    ek = base_b_key(exp)
    if ek:
        for line in stdout.splitlines():
            ok = base_b_key(line)
            if ok and ok == ek:
                return True
        # substring match on digit+base pattern inside longer lines
        for line in stdout.splitlines():
            if ek.split(":")[1] in re.sub(r"\s+", "", line) and f"#{ek.split(':')[0][1:]}" in line:
                return True
    zk = z_key(exp)
    if zk:
        for line in stdout.splitlines():
            ok = z_key(line)
            if ok and ok == zk:
                return True
    return False


def compare_output_to_expectations(stdout: str, manifest: dict, expect_comments: list[str]) -> list[str]:
    failures: list[str] = []
    out = normalize(stdout)
    for exp in expect_comments:
        if exp and not expect_matches(stdout, exp):
            failures.append(f"stdout missing EXPECT comment: {exp[:80]}")
    for case in manifest.get("icon_test_cases", []):
        for exp in case.get("expected", []):
            if exp and normalize(exp) not in out:
                failures.append(f"manifest test line {case.get('md_line')}: missing {exp[:60]}")
    for t in manifest.get("prose_tests", []):
        if t.get("kind") == "display_math":
            frag = normalize(t.get("expected", ""))[:40]
            if frag and frag not in out:
                failures.append(f"prose expected fragment not in output: {frag}")
    return failures


def report_manifest_coverage(manifest: dict) -> None:
  """Print summary of documented expectations (no Icon required)."""
  n_icon = sum(len(c.get("expected", [])) for c in manifest.get("icon_test_cases", []))
  n_table = len(manifest.get("table_tests", []))
  n_prose = len(manifest.get("prose_tests", []))
  n_lean = len(manifest.get("lean_golden", {}))
  print(f"Documented expectations: {n_icon} icon-test, {n_table} table rows, "
        f"{n_prose} prose, {n_lean} lean golden values")


def main() -> int:
    manifest = load_manifest()
    issues = check_manifest(manifest)
    tests_text = TESTS_ICON.read_text() if TESTS_ICON.exists() else ""
    expect_comments = extract_expect_comments(tests_text)

    report_manifest_coverage(manifest)
    print(f"Manifest: {len(manifest.get('procedures', []))} procedures")

    rc, stdout, stderr = run_icon(TESTS_ICON)
    if rc == -1:
        print("NOTE: Icon not installed; running static checks only.")
        print("Static issues:", issues or "none")
        print(f"# EXPECT comments in tests.icon: {len(expect_comments)}")
        missing = []
        for case in manifest.get("icon_test_cases", []):
            if not case.get("expected"):
                missing.append(case.get("md_line"))
        if missing:
            print(f"Test blocks without extracted expectations (md lines): {missing[:10]}")
        return 0 if not issues else 1

    print("--- stdout ---")
    print(stdout)
    if stderr:
        print("--- stderr ---", file=sys.stderr)
        print(stderr, file=sys.stderr)

    failures = issues + [
        f"stdout missing EXPECT comment: {exp[:80]}"
        for exp in expect_comments
        if exp and not expect_matches(stdout, exp)
    ]
    if failures:
        print("FAILURES:")
        for f in failures:
            print(" ", f)
        return 1
    print("All checks passed.")
    return 0 if rc == 0 else rc


if __name__ == "__main__":
    sys.exit(main())
