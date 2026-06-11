#!/usr/bin/env python3
"""Post-process extracted EUCLID Icon for the Icon compiler; sync MD snippets."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CODE = ROOT / "code.icn"
MD = ROOT / "Courant_Ericson_1986.md"

DIV_DIGITS_BODY = r'''
procedure div_digits(a, b, B)
  # If the divisor is 0, then fail.
  if (*b = 1) & (b[1] = 0) then { pr{"ERROR: divide by 0 in base_B"}; fail }
  # If a is shorter than b, return 0.
  if *a < *b then return [0]
  if *b = 1 then {
    q := list(*a, 0)
    rr := 0
    every j := 1 to *a do {
      du := rr * B + a[j]
      q[j] := du / b[1]
      rr := du % b[1]
    }
    return normalize_digits(q)
  }
  u := copy(a)
  v := copy(b)
  n := *v
  m := *u - n
  q := list(m + 1, 0)
  d := B / (v[1] + 1)
  u := times_digits(u, [d], B)
  if *u = m + n then u := catlist([0], u)
  v := times_digits(v, [d], B)
  every j := 1 to m + 1 do {
    if u[j] = v[1] then qe := B - 1 else qe := ((u[j] * B) + u[j + 1]) / v[1]
    while (v[2] * qe) > (((u[j] * B) + u[j + 1] - (qe * v[1])) * B + u[j + 2]) do qe -:= 1
    c := 0
    every k := n to 1 by -1 do {
      du := u[j + k] - (qe * v[k]) + c
      u[j + k] := du % B
      c := du / B
      if u[j + k] < 0 then { u[j + k] +:= B; c +:= 1 }
    }
    u[j] +:= c
    q[j] := qe
    if u[j] < 0 then {
      qe -:= 1
      c := 0
      every k := n to 1 by -1 do {
        u[j + k] +:= v[k] + c
        if u[j + k] >= B then { u[j + k] -:= B; c := 1 }
        else c := 0
      }
      u[j] +:= c
    }
  }
  return normalize_digits(q)
end
'''.strip()


def fix_code(text: str) -> str:
    # Drop duplicate generic div from operators block (keep first).
    text = re.sub(
        r"\n# --- div_213 \(md line 213\) ---\nprocedure div\(a, b\)\n  return proc\(\"div_\" \|\| type\(a\), 2\)\(a, b\)\nend\n",
        "\n",
        text,
        count=1,
    )

    # Integer plus must not redeclare generic plus.
    text = re.sub(
        r"(# --- plus_1232 \(md line 1232\) ---\n)procedure plus\(a, b\)",
        r"\1procedure plus_integer(a, b)",
        text,
    )

    # exp: avoid mod operator shadowed by procedure mod
    text = re.sub(r"\bif v mod 2 = 1\b", "if v % 2 = 1", text)

    if "procedure catlist(" not in text:
        text = text.replace(
            "# --- div (md line 61) ---\n",
            "# --- catlist (list concat; Icon || is string-only) ---\n"
            "procedure catlist(a, b)\n"
            "  local r, x\n"
            "  r := []\n"
            "  every x := !a do push(r, x)\n"
            "  every x := !b do push(r, x)\n"
            "  return r\nend\n\n"
            "# --- div (md line 61) ---\n",
            1,
        )

    # List concatenation: Icon || is string-only in this interpreter.
    text = re.sub(r"list\(([^)]+)\) \|\| ([a-zA-Z_.]+)", r"catlist(list(\1), \2)", text)
    text = re.sub(r"return digits_of\(x/B, B\) \|\| \[", r"return catlist(digits_of(x/B, B), [", text)
    text = re.sub(r"\[at\] \|\| plus_terms", r"catlist([at], plus_terms", text)
    text = re.sub(r"\[term\(([^]]+)\)\] \|\| plus_terms", r"catlist([term(\1)], plus_terms", text)
    text = re.sub(r"(\w+) \|\|:= \[([^\]]+)\]", r"push(\1, \2)", text)
    text = re.sub(
        r"return \[a\] \|\|:= \(if equal\(b, zero\(b\)\) then \[b\] else (MOD_RS|E_PRS)\(b, [^)]+\)\)",
        r"return catlist([a], if equal(b, zero(b)) then [b] else \1(b, mod(a, b)))",
        text,
    )
    text = re.sub(
        r"return \[a\] \|\|:= \(if equal\(b, zero\(b\)\) then \[b\] else E_PRS\(b, PREM\(a, b\)\)\)",
        "return catlist([a], if equal(b, zero(b)) then [b] else E_PRS(b, PREM(a, b)))",
        text,
    )
    text = re.sub(r"else P \|\|:= \[p_i\]", "else push(P, p_i)", text)

    if "procedure div_Z(" not in text:
        text = text.replace(
            "# --- mod_Z (md line 1104) ---\n",
            "# --- div_Z (synthesized) ---\n"
            "procedure div_Z(a, b)\n"
            "  return normalize_Z(Z(a.sign * b.sign, div_base_B(a.mantissa, b.mantissa)))\nend\n\n"
            "# --- mod_Z (md line 1104) ---\n",
            1,
        )

    # record base_B + globals
    text = re.sub(
        r"# --- record_base_B \(md line 459\) ---\nrecord base_B \(base, digits\)\n  global Base, Width\n  set_base\(b, w\) :=\n  Base := b\n  Width := \*\(b \|\| \"\"\) - 1\n",
        "# --- record_base_B (md line 459) ---\nrecord base_B(base, digits)\n\n"
        "global Base, Width\n\n"
        "procedure set_base(b, w)\n"
        "  Base := b\n"
        "  Width := *(b || \"\") - 1\n"
        "end\n\n",
        text,
    )

    # Borrow in subtraction
    text = re.sub(r"\{ u\[j\] \} B", "u[j] +:= B", text)
    text = re.sub(r"\{ u\[j \+ k\] \} B", "u[j + k] +:= B", text)
    text = re.sub(
        r"every j := \*u to 1 by -1 do\n  \{ u\[j\] := u\[j\] - v\[j\] \+ k\n  if u\[j\] < 0 then u\[j\] \+:= B; k := -1 \} else k := 0 \}",
        "every j := *u to 1 by -1 do {\n"
        "    u[j] := u[j] - v[j] + k\n"
        "    if u[j] < 0 then { u[j] +:= B; k := -1 } else k := 0\n"
        "  }",
        text,
    )

    # Replace incomplete div_digits (truncated or full)
    text = re.sub(
        r"# --- div_digits \(md line \d+\) ---\nprocedure div_digits\(a, b, B\).*?\nend\n",
        "# --- div_digits ---\n" + DIV_DIGITS_BODY + "\n",
        text,
        flags=re.S,
        count=1,
    )

    # >0_Z predicate
    text = re.sub(r">zero_Z\(", "gt0_Z(", text)
    text = re.sub(
        r"# --- anon \(md line 1159\) ---\ngt0_Z\(x\)  :=  return \(\(x\.sign = 1\) & not is_zero_Z\(x\)\)\n",
        "# --- gt0_Z (md line 1159) ---\nprocedure gt0_Z(x)\n"
        "  return ((x.sign = 1) & not is_zero_Z(x))\nend\n\n",
        text,
    )
    text = re.sub(
        r"# --- anon \(md line 1159\) ---\n>zero_Z\(x\)  :=  return \(\(x\.sign = 1\) & not is_zero_Z\(x\)\)\n",
        "# --- gt0_Z (md line 1159) ---\nprocedure gt0_Z(x)\n"
        "  return ((x.sign = 1) & not is_zero_Z(x))\nend\n\n",
        text,
    )

    # k_iQ_x
    text = re.sub(
        r"# --- anon_1337 \(md line 1337\) ---\nk_\{iQ_x\}\(l, j\)  :=  return term\(Q\(l, one\(l\)\), j\)\n",
        "# --- k_iQ_x (md line 1337) ---\nprocedure k_iQ_x(l, j)\n"
        "  return term(Q(l, one(l)), j)\nend\n\n",
        text,
    )

    # unit_modulo $mod$
    text = re.sub(
        r"equal\(\$mod\$\(a\.item, a\.modulus\), 1\)",
        "equal(a.item % a.modulus, 1)",
        text,
    )

    # record poly
    text = re.sub(
        r"# --- record_poly \(md line 1588\) ---\nrecord poly \(terms\)\n  poly_of\(x\) := return poly\(\[term\(x, 0\)\]\)\n",
        "# --- record_poly (md line 1588) ---\nrecord poly(terms)\n\n"
        "# --- poly_of (md line 1588) ---\nprocedure poly_of(x)\n"
        "  return poly([term(x, 0)])\nend\n\n",
        text,
    )

    # zeroth_coef
    text = re.sub(
        r"# --- anon_1602 \(md line 1602\) ---\n0th_coef\(fx\) :=\nlocal a\na := fx\.terms\[1\]\nreturn \(if a\.power = 0 then a\.coef else zero\(a\.coef\)\)\n",
        "# --- zeroth_coef (md line 1602) ---\nprocedure zeroth_coef(fx)\n"
        "  local a\n"
        "  a := fx.terms[1]\n"
        "  return (if a.power = 0 then a.coef else zero(a.coef))\nend\n\n",
        text,
    )
    text = text.replace("0th_coef(", "zeroth_coef(")

    # List append operators
    text = text.replace("||||||:=", "||:=")
    text = text.replace("||||:=", "||:=")
    text = text.replace("|||:=", "||:=")
    text = re.sub(r"(\S)\s*\}\s*(plus_terms|plus_poly|MOD_RS|E_PRS)", r"\1 || \2", text)
    text = re.sub(r"\]\s*\}\s*(plus_terms)", r"] || \1", text)

    # MOD_RS / E_PRS return forms
    text = re.sub(
        r"return \[a\] \|\|:= \(if equal\(b, zero\(b\)\) then \[b\] else MOD_RS\(b, mod\(a, b\)\)\)",
        "return [a] ||:= (if equal(b, zero(b)) then [b] else MOD_RS(b, mod(a, b)))",
        text,
    )

    # Subscripted identifiers from math notation
    subs = [
        (r"delta_i-2", "delta_i_minus_2"),
        (r"delta_i-1", "delta_i_minus_1"),
        (r"c_i-2", "c_i_minus_2"),
        (r"R_i-2", "R_i_minus_2"),
        (r"p_i-2", "p_i_minus_2"),
        (r"p_i-1", "p_i_minus_1"),
        (r"p_i\+1", "p_i_plus_1"),
    ]
    for pat, rep in subs:
        text = re.sub(pat, rep, text)

    text = text.replace("equal(%(a.item, a.modulus), 1)", "equal(a.item % a.modulus, 1)")
    if "procedure set_base" not in text:
        text = text.replace(
            "# --- zero_base_B",
            "# --- record_base_B ---\nrecord base_B(base, digits)\n\n"
            "global Base, Width\n\n"
            "procedure set_base(b, w)\n  Base := b\n  Width := *(b || \"\") - 1\nend\n\n"
            "# --- zero_base_B",
            1,
        )
    text = re.sub(
        r"# --- record_poly[^\n]*\nrecord poly\(terms\)\n  poly_of\(x\) := return poly\(\[term\(x, 0\)\]\)\n",
        "# --- record_poly ---\nrecord poly(terms)\n\n"
        "# --- poly_of ---\nprocedure poly_of(x)\n  return poly([term(x, 0)])\nend\n\n",
        text,
    )

    text = text.replace("≠", "~==")
    text = text.replace("!=", "~==")
    text = re.sub(r"R_i-1", "R_i_minus_1", text)
    text = re.sub(
        r'else pr\{"ERROR: ", a, "\^\{-1 "\}, " mod ", m, " does not exist"\}',
        'else pr{"ERROR: ", a, " inverse mod ", m, " does not exist"}',
        text,
    )
    text = re.sub(
        r"then plus_Z\(a, minus_Z\(times_Z\(b, plus_Z\(minus_Z\(one_Z\(a\)\), div_Z\(a, b\)\)\)\)\n"
        r"  else plus_Z\(a, minus_Z\(times_Z\(b, div_Z\(a, b\)\)\)\) \)",
        "then plus_Z(a, minus_Z(times_Z(b, plus_Z(minus_Z(one_Z(a)), div_Z(a, b)))))\n"
        "  else plus_Z(a, minus_Z(times_Z(b, div_Z(a, b))))\n  )",
        text,
    )

    # FFT locals and comments
    text = re.sub(
        r"procedure FFT\(N, ax, omega\)\n  local A, n, bx, cx, omega\^2, B, C, omega\^k\n",
        "procedure FFT(N, ax, omega)\n  local A, n, bx, cx, omega2, B, C, omega_k\n",
        text,
    )
    text = text.replace("if N = 1 * basis", "if N = 1 then { # basis")
    text = text.replace("then A[1] := 0th_coef(ax)", "then A[1] := zeroth_coef(ax); return A }")
    text = text.replace("n := N/2 * binary split", "n := N/2; # binary split")
    text = text.replace("omega^2 := exp(omega, 2)", "omega2 := exp(omega, 2)")
    text = text.replace("B := FFT(n, bx, omega^2) * recursive calls", "B := FFT(n, bx, omega2)")
    text = text.replace("C := FFT(n, cx, omega^2)", "C := FFT(n, cx, omega2)")
    text = text.replace("omega^k := exp(omega, k-1)", "omega_k := exp(omega, k - 1)")
    text = text.replace("times(omega^k, C[k])", "times(omega_k, C[k])")
    text = text.replace("times(omega^k, C[k])", "times(omega_k, C[k])")
    text = text.replace("ominus(B[k], times(omega^k, C[k]))", "ominus(B[k], times(omega_k, C[k]))")

    # NPSI exponent
    text = re.sub(r"truncate\(ax, 2\^\{k\+1\}\)", "truncate(ax, 2 ^ (k + 1))", text)

    # geq in any leftover
    text = text.replace(" geq ", " >= ")
    text = text.replace("|||", "||")

    # Library module: no main (tests.icn supplies main).
    text = re.sub(
        r"\nprocedure main\(\)\n  # Library module:.*?\nend\n",
        "\n",
        text,
        flags=re.S,
    )

    if "invocable all" not in text:
        text = text.replace(
            "# --- prs (md line 411) ---\nprocedure prs(x)",
            "invocable all\n\n# --- prs (md line 411) ---\nprocedure prs(x)",
            1,
        )

    inserts = [
        ("# --- zero_Z (md line 971) ---\n", "record Z(sign, mantissa)\n\n# --- zero_Z (md line 971) ---\n"),
        ("# --- zero_Q (md line 1340) ---\n", "record Q(dividend, divisor)\n\n# --- zero_Q (md line 1340) ---\n"),
        ("# --- zero_modulo (md line 1502) ---\n", "record modulo(item, modulus)\n\n# --- zero_modulo (md line 1502) ---\n"),
        ("record poly(terms)\n", "record term(coef, power)\n\nrecord poly(terms)\n"),
        ("# --- zero_tpower (md line 2136) ---\n", "record tpower(Poly, N)\n\n# --- zero_tpower (md line 2136) ---\n"),
    ]
    for needle, block in inserts:
        if needle in text and block.split("\n\n")[0].strip() not in text:
            text = text.replace(needle, block, 1)

    return text


MD_REPLACEMENTS: list[tuple[str, str]] = [
    (
        "record base_B (base, digits)\nglobal Base, Width\nset_base(b, w) ←\nBase := b\nWidth := *(b || \"\") - 1 ■",
        "record base_B(base, digits)\n\nglobal Base, Width\n\nprocedure set_base(b, w)\n  Base := b\n  Width := *(b || \"\") - 1\nend",
    ),
    (">0_Z(x) ← ↑ ((x.sign = 1) & not =0_Z(x)) ■", "gt0_Z(x) ← ↑ ((x.sign = 1) & not =0_Z(x)) ■"),
    (">zero_Z(", "gt0_Z("),
    ("k_{imathcal{Q}_x}(l, j) ←", "k_iQ_x(l, j) ←"),
    ("k_{iQ_x}(l, j) ←", "k_iQ_x(l, j) ←"),
    ("record poly (terms)\npoly_of(x) ← ↑ poly([term(x, 0)]) ■", "record poly(terms)\n\npoly_of(x) ← ↑ poly([term(x, 0)]) ■"),
    ("0th_coef(fx) ←", "zeroth_coef(fx) ←"),
    ("0th_coef(", "zeroth_coef("),
    ("if u[j] < 0 then { u[j] } B", "if u[j] < 0 then u[j] +:= B"),
    ("|||", "||"),
    ("{:=}}", "-:="),
    ("$mod$(a.item, a.modulus)", "a.item % a.modulus"),
    ("⊕(a, b) ← ↑ a + b ■", "plus_integer(a, b) ← ↑ a + b ■"),
    ("if v mod 2 = 1", "if v % 2 = 1"),
    ("omega^2", "omega2"),
    ("omega^k", "omega_k"),
    ("p_i+1", "p_i_plus_1"),
    ("p_i-2", "p_i_minus_2"),
    ("p_i-1", "p_i_minus_1"),
    ("delta_i-2", "delta_i_minus_2"),
    ("delta_i-1", "delta_i_minus_1"),
    ("c_i-2", "c_i_minus_2"),
    ("R_i-2", "R_i_minus_2"),
    ("[at] } ⊕_terms", "[at] || ⊕_terms"),
    ("[term(c_coef, ap)] } ⊕_terms", "[term(c_coef, ap)] || ⊕_terms"),
    ("if *u = m + n then u := [0] } u", "if *u = m + n then u := [0] || u"),
    ("If the divisor is 0, then fail.", "# If the divisor is 0, then fail."),
    ("If a is shorter than b, return 0.", "# If a is shorter than b, return 0."),
]


def fix_md(text: str) -> str:
    for old, new in MD_REPLACEMENTS:
        text = text.replace(old, new)
    return text


def run_icon() -> tuple[int, str]:
    p = subprocess.run(["icon", "-c", str(CODE)], capture_output=True, text=True, cwd=ROOT)
    return p.returncode, p.stdout + p.stderr


def main() -> int:
    code = CODE.read_text()
    code = fix_code(code)
    CODE.write_text(code)

    md = MD.read_text()
    MD.write_text(fix_md(md))

    rc, out = run_icon()
    print(out)
    if rc == 0:
        print("code.icn compiles cleanly.")
    else:
        print("Remaining errors above.")
    return rc


if __name__ == "__main__":
    sys.exit(main())
