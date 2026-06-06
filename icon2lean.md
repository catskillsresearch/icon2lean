# From 1986 Icon to Modern Lean 4: A 40-Year Journey in Formalized Computer Algebra

In August 1986, at New York University’s Courant Institute of Mathematical Sciences, I authored NYU Computer Science Technical Report #232: **"An ICON Package for Experimenting with Euclidean Domains"** [1]. The goal was to build a computationally generic playground to study algebraic algorithms over mathematical structures like integers, quotient rings, polynomials, and power series, following John Lipson’s text, *Elements of Algebra and Algebraic Computing* [1, 2].

At the time, the programming language of choice for rapid software prototyping was **Icon** [1, 2]. Icon lacked native typeclasses or object-oriented dispatch [2]. To implement generic division and arithmetic operations across distinct domains, I built a custom runtime dispatch system using string reflection [2].

This repository contains a **1:1 Lean 4 translation** of the report’s domain types (Section 2) and application algorithms (Section 1.2 / Section 3), with **no `sorry`s**. Source Icon and OCR’d listings live in [`Courant_Ericson_1986.md`](Courant_Ericson_1986.md); the executable port lives in [`Icon2lean/`](Icon2lean/).

> **Notation.** Icon listings follow the report’s *fancy notation* (Section 1.3 of [1]): `©` is division, `®` is addition, `—` is subtraction, `F (args) <= body ■` is a procedure definition, and `■` marks return.

---

## Lean library map

| Report | Lean module | Definitions |
|--------|-------------|-------------|
| `base_b`, `tpower` | [`Icon2lean/Types.lean`](Icon2lean/Types.lean) | `BaseB`, `TPower`, `truncateTo`, `tpowerMk` |
| `GCD`, `EUCLID`, `INVERSE` | [`Icon2lean/Gcd.lean`](Icon2lean/Gcd.lean) | `gcdInt`, `euclidInt`, `modularInverse` |
| `CRA1`, `CRA2`, `CRA` | [`Icon2lean/Congruence.lean`](Icon2lean/Congruence.lean) | `cra1`, `cra2`, `cra` |
| `DIOPHANTINE` | [`Icon2lean/Diophantine.lean`](Icon2lean/Diophantine.lean) | `diophantine` |
| `MOD_RS`, `PREM`, `E_PRS`, `S_PRS` | [`Icon2lean/Polynomial.lean`](Icon2lean/Polynomial.lean) | `modRS`, `prem`, `ePRS`, `sPRS` |
| `NIA` | [`Icon2lean/Interpolation.lean`](Icon2lean/Interpolation.lean) | `newtonInterpolation` |
| `FFT`, `FFI` | [`Icon2lean/Fft.lean`](Icon2lean/Fft.lean) | `evenTerms`, `oddTerms`, `fftCoeffs`, `ffi` |
| `NPSI` | [`Icon2lean/PowerSeries.lean`](Icon2lean/PowerSeries.lean) | `npsiStep`, `npsi`, `npsiTpower` |

Build and reproduce examples:

```bash
lake update    # first clone only
lake build     # typechecks everything; zero sorry
```

Automated checks for **§3.1 integer examples** are in [`Icon2lean/Tests.lean`](Icon2lean/Tests.lean).

---

## Part 1: Domain types (Section 2)

The 1986 package implements primitive domains and constructors listed in Table 1 of [1]. In Lean we use native Mathlib types where they match the report exactly, and small structures where they do not.

### `Z` — arbitrary-precision integers

* **Icon:** `record Z (sign, mantissa)` with constructor `kz`.
* **Lean:** `Int` (Mathlib). No separate record needed.

### `base_b` — unsigned base-`B` integers

* **Icon:**
  ```icon
  record base_b (base, digits)
  ```
* **Lean:** [`Icon2lean/Types.lean`](Icon2lean/Types.lean)
  ```lean
  structure BaseB (B : Nat) where
    digits : List Nat
    h_digits : ∀ d ∈ digits, d < B
    h_base : 1 < B

  def base10_5335 : BaseB 10 := { digits := [5, 3, 3, 5], ... }
  ```
  Report example: `baseB(10, [5, 3, 3, 5])` (§2.2.2).

### `Q` — quotient domain

* **Icon:** `record Q (dividend, divisor)`.
* **Lean:** `Rat` for `QZ`, or `FractionRing R` for general `R`.

### `modulo` — modular elements

* **Icon:** `record modulo (item, modulus)`.
* **Lean:** `ZMod n` for integer moduli.

### `poly` / `term` — polynomials

* **Icon:** `record poly (terms)`, `record term (coef, power)`.
* **Lean:** `Polynomial R` (Mathlib). Report example $x^3 - 2$ over `Q`: `X ^ 3 - C 2`.

### `tpower` — truncated power series

* **Icon:**
  ```icon
  record tpower (poly, N)
  ```
* **Lean:** [`Icon2lean/Types.lean`](Icon2lean/Types.lean)
  ```lean
  structure TPower (R : Type*) [CommRing R] where
    poly : Polynomial R
    N : Nat

  def truncateTo (N : Nat) (p : Polynomial R) : Polynomial R := p %ₘ (X ^ N)
  ```

*(Full domain arithmetic — `baseB` add/mul/div, `Q` normalization, etc. — is in the Icon source but not re-ported here; this Lean project covers the Section 3 application algorithms and the two supporting record types above.)*

---

## Part 2: Application algorithms (Section 3)

Fourteen algorithms from Section 1.2 of [1]. Each subsection gives the **Icon definition from the report**, the **Lean definition** (same file as in the table above), and **report examples** where the paper prints explicit outputs.

### §3.1.1 — `GCD` and `EUCLID`

* **Icon `GCD`:**
  ```icon
  GCD (a, b) <= ■ (if =(b, 0(b)) then normalize(a) else GCD(b, mod(a, b)))
  ```
* **Icon `EUCLID`:**
  ```icon
  EUCLID (A, B) <=
    local q, a, s, t
    a := [copy(A), copy(B)]
    s := [1(A), 0(A)]
    t := [0(A), 1(A)]
    while not(=(a[2], 0(A))) do
    { q := ©(a[1], a[2])
      a := [a[2], —(a[1], *(a[2], q))]
      s := [s[2], —(s[1], *(s[2], q))]
      t := [t[2], —(t[1], *(t[2], q))] }
    ■ [normalize(a[1]), normalize(s[1]), normalize(t[1])]
  ```
* **Lean:** [`Icon2lean/Gcd.lean`](Icon2lean/Gcd.lean)
  ```lean
  def gcdInt (a b : Int) : Nat := Int.gcd a b

  def euclidInt (A B : Int) : Nat × Int × Int :=
    (Int.gcd A B, Int.gcdA A B, Int.gcdB A B)
  ```
* **Report example (extended gcd table, machine integers):** `EUCLID(84, 54) = [6, 2, -3]`. Checked in `Tests.lean`.

### §3.1.2 — `INVERSE`

* **Icon:**
  ```icon
  INVERSE (a, m) <=
    local gst
    gst := EUCLID(m, a)
    if unit(gst[1]) then ■ mod(©(gst[3], gst[1]), m)
    else pr{"ERROR: ", a, "^-1 ", " mod ", m, " does not exist"}
  ```
  Argument order is **`EUCLID(m, a)`**, not `(a, m)`.
* **Lean:** [`Icon2lean/Gcd.lean`](Icon2lean/Gcd.lean) — `modularInverse` uses `Int.gcdB m a` after `Int.gcd m a`.

### §3.1.3 — `CRA1`, `CRA2`, `CRA`

* **Icon `CRA1`:**
  ```icon
  CRA1 (aa, bb, m) <=
    local a, b, g
    g := GCD(aa, m)
    if not |(g, bb) then pr{"ERROR: no solution to linear congruence"}
    else { a := mod(aa, m); b := mod(bb, m)
           if =(a, 1(a)) then b
           else if =(b, 0(b)) then 0(b)
           else div(add(mul(m, CRA1(m, -(b), a)), b), a) }
  ```
* **Icon `CRA2`:**
  ```icon
  CRA2 (r, m, s, n) <=
    local c, sigma, U
    c := INVERSE(m, n)
    sigma := mod(*(sub(s, r), c), n)
    U := add(r, mul(sigma, m))
    ■ U
  ```
* **Icon `CRA`:**
  ```icon
  CRA (rm_list) <=
    local rms, rm, M, U, c, t
    rms := copy(rm_list)
    rm := pop(rms); r := rm[1]; m := rm[2]
    U := mod(r, m)
    every k := 1 to *rms do
    { M := *(M, m)
      rm := pop(rms); r := rm[1]; m := rm[2]
      c := INVERSE(M, m)
      t := mod(*(sub(mod(U, m), r), c), m)
      U := add(U, *(t, M)) }
    ■ U
  ```
* **Lean:** [`Icon2lean/Congruence.lean`](Icon2lean/Congruence.lean) — uses `iconMod` (`Int.emod`) to match Icon’s non-negative `mod`.
* **Report examples (checked in `Tests.lean`):**

  | Call | Expected |
  |------|----------|
  | `CRA1(7, 1432, 5317)` | `4762` |
  | `CRA1(863, 880, 2151)` | `173` |
  | `CRA1(589, 509, 817)` | no solution |
  | `CRA2(6, 7, 3, 9)` | `48` |
  | `CRA([[1,3],[3,5],[0,7],[10,11]])` | `868` |

### §3.1.4 — `DIOPHANTINE`

* **Icon:**
  ```icon
  DIOPHANTINE (a, b, c) <=
    local gst, g, xi, yi
    gst := EUCLID(a, b)
    g := gst[1]; t := gst[3]
    if not |(g, c) then pr{"ERROR: Diophantine solution nonexistent"}
    else { if <(abs(b), abs(a))
           then { xi := CRA1(a, c, abs(b))
                  yi := div(sub(c, mul(b, xi)), a) }
           else { yi := CRA1(b, c, abs(a))
                  xi := div(sub(c, mul(a, yi)), b) }
           ■ [g, xi, yi] }
  ```
* **Lean:** [`Icon2lean/Diophantine.lean`](Icon2lean/Diophantine.lean) — `diophantine` follows the `CRA1` path above.
* **Report examples (particular `(x₀, y₀)`, checked in `Tests.lean`):**

  | Equation | Particular solution |
  |----------|---------------------|
  | `84x + 54y = -24` | `(1, -2)` |
  | `999x - 49y = 5000` | `(13, 163)` |
  | `247x + 589y = 817` | `(-11, 6)` |

### §3.2.1 — `MOD_RS`

* **Icon:**
  ```icon
  MOD_RS (a, b) <= ■ [a] ||| (if =(b, 0(b)) then [b] else MOD_RS(b, mod(a, b)))
  ```
* **Lean:** [`Icon2lean/Polynomial.lean`](Icon2lean/Polynomial.lean) — `modRS`
* **Report example (QZ[x]):** remainder sequence of
  `ax = 2 + (-1)X + 3X² + 2X⁴ + X⁵`,
  `bx = 2 + (-1)X + 3X³`
  has **five** terms, last term **0** (full list printed in [1], §3.2.1).

### §3.2.2 — `PREM`

* **Icon:**
  ```icon
  PREM (px, qx) <=
    local d, b
    d := —(deg_poly(px), deg_poly(qx))
    b := poly_of(lead_coef(qx))
    ■ rem(*(exp(b, d + 1), px), qx)
  ```
* **Lean:** [`Icon2lean/Polynomial.lean`](Icon2lean/Polynomial.lean) — `prem`
* **Report example:** `prem(p, q)` with
  `p = 22 - X + 3X² + 22X⁴ + X⁶`,
  `q = 2 - X + 3X³`
  yields **`198 - 225X + 306X³`** over QZ[x].

### §3.2.3 — `E_PRS`

* **Icon:**
  ```icon
  E_PRS (a, b) <= ■ [a] ||| (if =(b, 0(b)) then [b] else E_PRS(b, PREM(a, b)))
  ```
* **Lean:** [`Icon2lean/Polynomial.lean`](Icon2lean/Polynomial.lean) — `ePRS`

### §3.2.4 — `S_PRS`

* **Icon:** Collins–Brown subresultant PRS (full listing in [1], §3.2.4).
* **Lean:** [`Icon2lean/Polynomial.lean`](Icon2lean/Polynomial.lean) — `sPRS`

### §3.3.1 — `NIA`

* **Icon:** Newton interpolation (`NIA (ab_list)` — listing in [1], §3.3.1).
* **Lean:** [`Icon2lean/Interpolation.lean`](Icon2lean/Interpolation.lean) — `newtonInterpolation`

### §3.3.2 — `FFT` and `FFI`

* **Icon `FFT`:** Cooley–Tukey decimation on even/odd powered terms (listing in [1], §3.3.2).
* **Icon `FFI`:**
  ```icon
  FFI (N, B, omega) <=
    local bx, C, ax
    bx := polynomialize(B)
    C := FFT(N, bx, inverse(omega))
    ax := polynomialize(scalarVector(C, inverse(N)))
    ■ ax
  ```
* **Lean:** [`Icon2lean/Fft.lean`](Icon2lean/Fft.lean) — `evenTerms`, `oddTerms`, `fftCoeffs`, `ffi`

### §3.3.3 — `NPSI`

* **Icon:** Newton truncated power-series inversion (`NPSI (at)` — listing in [1], §3.3.3).
* **Lean:** [`Icon2lean/PowerSeries.lean`](Icon2lean/PowerSeries.lean) — `npsi`, `npsiTpower`

---

## What is intentionally omitted

Per the report itself, we omit utilities that are not mathematical core:

* Runtime **dispatch** (`div`, `mod`, … by domain type) — replaced by Lean typeclasses and fixed modules.
* **Timer** (`settime` / `showtime`, §3.4) and **pretty-printer** pipeline (§4).
* Full **base-B long arithmetic** (§2.2) — only the `BaseB` type is ported.

---

## Conclusion

The 1986 package validated algorithms on selected inputs. The Lean port preserves those algorithms and checks the report’s **§3.1 integer examples** automatically. Polynomial and series examples from §3.2–§3.3 can be replayed by importing the corresponding `Icon2lean` module in a Lean session after `lake build`.

The next step — not done here — would be **correctness proofs** (e.g. that `cra2` satisfies both congruences), which Lean makes possible but which the original Icon code never attempted.

---

### References

* [1] Lars Warren Ericson, *"An ICON Package for Experimenting with Euclidean Domains"*, NYU CS TR #232, August 1986. ([`Courant_Ericson_1986.md`](Courant_Ericson_1986.md))
* [2] Technical Report #232, Section 1: *Introduction & Programming with Euclidean Domains*.
* [3] Technical Report #232, Section 2: *Euclidean domains: representation and basic arithmetic*.
* [4] Technical Report #232, Section 3: *Algorithms for various problems over Euclidean domains*.
