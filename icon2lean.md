# From 1986 Icon to Modern Lean 4: A 40-Year Journey in Formalized Computer Algebra

In August 1986, at New York University’s Courant Institute of Mathematical Sciences, I authored NYU Computer Science Technical Report #232: **"An ICON Package for Experimenting with Euclidean Domains"** [1]. The goal was to build a computationally generic playground to study algebraic algorithms over mathematical structures like integers, quotient rings, polynomials, and power series, following John Lipson’s text, *Elements of Algebra and Algebraic Computing* [1, 2].

At the time, the programming language of choice for rapid software prototyping was **Icon** [1, 2]. Icon lacked native typeclasses or object-oriented dispatch [2]. To implement generic division and arithmetic operations across distinct domains, I had to build a custom runtime dispatch system using string reflection [2].

Looking back at that 1986 report from 2026, the contrast is immense. By moving from Icon to **Lean 4** and **Mathlib 4**, we transition from a dynamically typed scripting language to a statically typed, formally verified environment where algorithms are not just run—they are mathematically proven correct [1, 2].

> **Notation.** Icon listings below follow the report’s *fancy notation* (Section 1.3 of [1]): `©` is division, `®` is addition, `—` is subtraction, `F (args) <= body ■` is a procedure definition, and `■` marks return. These are presentation conventions in the report, not raw Icon syntax.

---

## Part 1: Representation of Algebraic Types

The original Icon package relied on structural record types [2, 3]. In Lean 4, these structures are formalized as types governed by compile-time checked typeclasses.

### Type 1: Arbitrary-Precision Integers (`Z`)
* **Original Icon Type:** Modeled using a dedicated sign/mantissa representation [3]:
  ```icon
  record Z (sign, mantissa)
  ```
  Values are built with the constructor `kz`, e.g. `x := kz(1)`.
* **New Lean 4 / Mathlib Type:** Fully replaced by Lean's native arbitrary-precision `Int` type. Mathlib gives `Int` a `EuclideanDomain` instance, so division, `gcd`, and `mod` are available generically.
* **Value Creation Demo:**
  * *Icon (1986):*
    ```icon
    x := kz(1)
    y := kz(-999)
    # Result of 1z + (-999z) was (-998z)
    ```
  * *Lean 4 (2026):*
    ```lean
    import Mathlib.Data.Int.Basic

    -- Paste into Lean 4 Web:
    def z_val1 : Int := 1
    def z_val2 : Int := -999
    def z_sum : Int := z_val1 + z_val2
    -- #eval z_sum  -- expected: (-998 : Int)
    ```

### Type 2: Unsigned Arbitrary-Base Integers (`base_B`)
* **Original Icon Type:** Represented as an arbitrary radix container [3]:
  ```icon
  record base_b (base, digits)
  ```
* **New Lean 4 / Mathlib Type:** There is no direct Mathlib counterpart for the report’s unsigned multi-precision base‑`B` integers. A faithful translation bundles a digit list with proofs that the base exceeds 1 and every digit is strictly below the base.
* **Value Creation Demo:**
  * *Icon (1986):*
    ```icon
    x := base_b(8, [1])
    ```
  * *Lean 4 (2026):*
    ```lean
    import Mathlib.Data.List.Basic

    -- Paste into Lean 4 Web:
    structure BaseB (B : Nat) where
      digits : List Nat
      h_digits : ∀ d ∈ digits, d < B
      h_base : 1 < B

    def x_base8 : BaseB 8 := {
      digits := [1],
      h_digits := by decide,
      h_base := by decide
    }
    ```

### Type 3: Quotient Domain (`Q`)
* **Original Icon Type:** Represented fractional fields over arbitrary Euclidean domains [3]:
  ```icon
  record Q (dividend, divisor)
  ```
  The package implements `Q` generically over any Euclidean domain `D`, not only over the rationals.
* **New Lean 4 / Mathlib Type:** For coefficients in `ℤ`, use `Rat` (i.e. `ℚ`). For a general integral domain `R`, use `FractionRing R` (or `IsFractionRing` APIs when working in a field of fractions).
* **Value Creation Demo:**
  * *Icon (1986):*
    ```icon
    half := Q(1, 2)
    ```
  * *Lean 4 (2026):*
    ```lean
    import Mathlib.Data.Rat.Defs

    -- Paste into Lean 4 Web:
    def half : Rat := (1 : Rat) / 2
    ```

### Type 4: Modular Arithmetic Elements (`modulo`)
* **Original Icon Type:** Represented items under a specific modular congruence [3]:
  ```icon
  record modulo (item, modulus)
  ```
* **New Lean 4 / Mathlib Type:** For integer moduli, formalized as `ZMod n` (requires `[NeZero n]` when `n = 0` is excluded).
* **Value Creation Demo:**
  * *Icon (1986):*
    ```icon
    val := modulo(-2, 5)
    ```
  * *Lean 4 (2026):*
    ```lean
    import Mathlib.Data.ZMod.Basic

    -- Paste into Lean 4 Web:
    def val_mod5 : ZMod 5 := (-2 : ZMod 5)  -- coerces to 3 mod 5
    ```

### Type 5: Polynomial Rings (`poly` & `term`)
* **Original Icon Type:** Modeled via coefficient-power term structures [3]:
  ```icon
  record poly (terms)
  record term (coef, power)
  ```
* **New Lean 4 / Mathlib Type:** Represented via Mathlib's `Polynomial R` (notation `R[X]`).
* **Value Creation Demo:**
  * *Icon (1986):* Representing the polynomial $x^3 - 2$ with rational coefficients:
    ```icon
    ax := poly([term(Q(-2, 1), 0), term(Q(1, 1), 3)])
    ```
  * *Lean 4 (2026):*
    ```lean
    import Mathlib.Algebra.Polynomial.Basic

    open Polynomial

    -- Paste into Lean 4 Web:
    def poly_val : Polynomial Rat := X ^ 3 - C 2
    ```

### Type 6: Truncated Power Series (`tpower`)
* **Original Icon Type:** Represents truncated series bounded to power $N$ [3]:
  ```icon
  record tpower (poly, N)
  ```
* **New Lean 4 / Mathlib Type:** The report’s `truncate` keeps terms of degree `< N`. For univariate polynomials this matches working in the quotient ring `R[X] ⧸ Ideal.span {X ^ N}` (equivalently, reducing modulo `X ^ N`).
* **Value Creation Demo:**
  * *Icon (1986):*
    ```icon
    ax := poly([term(Q(-2, 1), 0), term(Q(1, 1), 3)])
    ts := tpower(ax, 3)
    ```
  * *Lean 4 (2026):*
    ```lean
    import Mathlib.Algebra.Polynomial.Basic

    open Polynomial

    -- Paste into Lean 4 Web:
    def truncateTo (N : Nat) (p : Polynomial Rat) : Polynomial Rat :=
      p % (X ^ N)
    ```

---

## Part 2: Implementation of Algebraic Algorithms

The 1986 package implements fourteen application algorithms over generic Euclidean domains (Section 1.2 of [1]). A compile-checked Lean 4 port lives under [`Icon2lean/`](Icon2lean/) and builds with `lake build` (zero `sorry`s). Below we map each algorithm to Icon source and Lean code.

### Algorithm 1: Greatest Common Divisor (`GCD`)
* **Original Icon Code** [4]:
  ```icon
  GCD (a, b) <= ■(if =(b, 0(b)) then normalize(a) else GCD(b, mod(a, b)))
  ```
* **New Lean 4 / Mathlib Algorithm:**
  ```lean
  import Mathlib.Data.Int.GCD

  -- Paste into Lean 4 Web:
  def compute_gcd (a b : Int) : Nat :=
    Int.gcd a b
  ```

### Algorithm 2: Extended GCD (`EUCLID`)
* **Original Icon Code** [4]:
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
  Returns `[g, s, t]` with `g = s*A + t*B` (Icon uses 1-based list indexing).
* **New Lean 4 / Mathlib Algorithm:**
  ```lean
  import Mathlib.Data.Int.GCD

  -- Paste into Lean 4 Web:
  def compute_euclid (A B : Int) : Nat × Int × Int :=
    (Int.gcd A B, Int.gcdA A B, Int.gcdB A B)
  -- Bézout identity: (Int.gcd A B : Int) = Int.gcdA A B * A + Int.gcdB A B * B
  ```

### Algorithm 3: Polynomial Remainder Sequence (`MOD_RS`)
* **Original Icon Code** [4]:
  ```icon
  MOD_RS (a, b) <= ■ [a] ||| (if =(b, 0(b)) then [b] else MOD_RS(b, mod(a, b)))
  ```
* **New Lean 4 / Mathlib Algorithm:**
  ```lean
  import Mathlib.Algebra.Polynomial.Basic
  import Mathlib.Algebra.EuclideanDomain.Defs

  open Polynomial

  -- Requires a field of coefficients so R[X] is a Euclidean domain.
  -- Paste into Lean 4 Web:
  partial def modRS [Field R] [DecidableEq R]
      (a b : Polynomial R) : List (Polynomial R) :=
    if b = 0 then [a]
    else a :: modRS b (a % b)
  ```

### Algorithm 4: Pseudo-Remainder (`PREM`)
* **Original Icon Code** [4]:
  ```icon
  PREM (px, qx) <=
    local d, b
    d := —(deg_poly(px), deg_poly(qx))
    b := poly_of(lead_coef(qx))
    ■ rem(*(exp(b, d + 1), px), qx)
  ```
* **New Lean 4 / Mathlib Algorithm:**
  ```lean
  import Mathlib.Algebra.Polynomial.Basic

  open Polynomial

  -- Paste into Lean 4 Web:
  def prem [CommRing R] [IsDomain R] [DecidableEq R]
      (p q : Polynomial R) : Polynomial R :=
    if q = 0 then p
    else
      let d := max 0 (p.natDegree - q.natDegree)
      let b := q.leadingCoeff
      (C (b ^ (d + 1)) * p) % q
  ```

### Algorithm 5: PREM-based PRS (`E_PRS`)
* **Original Icon Code** [4]:
  ```icon
  E_PRS (a, b) <= ■ [a] ||| (if =(b, 0(b)) then [b] else E_PRS(b, PREM(a, b)))
  ```
* **New Lean 4 / Mathlib Algorithm:**
  ```lean
  import Mathlib.Algebra.Polynomial.Basic

  open Polynomial

  partial def ePRS [CommRing R] [IsDomain R] [DecidableEq R]
      (a b : Polynomial R) : List (Polynomial R) :=
    if b = 0 then [a]
    else a :: ePRS b (prem a b)
  ```

### Algorithm 6: Modular Inverse (`INVERSE`)
* **Original Icon Code** [4]:
  ```icon
  INVERSE (a, m) <=
    local gst
    gst := EUCLID(m, a)
    if unit(gst[1]) then ■ mod(©(gst[3], gst[1]), m)
    else pr{"ERROR: ", a, "^-1 ", " mod ", m, " does not exist"}
  ```
  Note the argument order: extended gcd is computed on `(m, a)`, not `(a, m)`.
* **New Lean 4 / Mathlib Algorithm:**
  ```lean
  import Mathlib.Data.Int.GCD

  -- Paste into Lean 4 Web:
  def modularInverse (a m : Int) : Option Int :=
    let g := Int.gcd m a
    if g = 1 then
      Some ((Int.gcdB m a / (g : Int)) % m)
    else
      none
  ```

### Algorithm 7: Newton Interpolation (`NIA`)
* **Original Icon Code** [4]:
  ```icon
  NIA (ab_list) <=
    local ab_s, ab, a, b, Ux, Mx, c, sigma
    ab_s := copy(ab_list)
    ab := pop(ab_s); a := ab[1]; b := ab[2]
    Ux := poly_of(b)
    Mx := 1(Ux)
    every k := 1 to *ab_s do
    { Mx := *(Mx, —(poly([term(1(b), 1)]), poly_of(a)))
      ab := pop(ab_s); a := ab[1]; b := ab[2]
      c := ©(1(a), eval_poly(Mx, a))
      sigma := *(—(poly_of(b), poly_of(eval_poly(Ux, a))), poly_of(c))
      Ux := ®(Ux, *(sigma, Mx)) }
    ■ Ux
  ```
* **New Lean 4 / Mathlib Algorithm:**
  ```lean
  import Mathlib.Algebra.Polynomial.Basic

  open Polynomial

  -- Paste into Lean 4 Web:
  def newtonInterpolation [Field R] [DecidableEq R] (points : List (R × R)) : Polynomial R :=
    match points with
    | [] => 0
    | (a₀, b₀) :: rest =>
      let rec loop (pts : List (R × R)) (u : Polynomial R) (m : Polynomial R) : Polynomial R :=
        match pts with
        | [] => u
        | (a, b) :: xs =>
          let c := (b - u.eval a) / m.eval a
          let u' := u + C c * m
          let m' := m * (X - C a)
          loop xs u' m'
      loop rest (C b₀) (X - C a₀)
  ```

### Algorithm 8: Chinese Remainder Algorithm (`CRA2`)
* **Original Icon Code** [4]:
  ```icon
  CRA2 (r, m, s, n) <=
    local c, sigma, U
    c := INVERSE(m, n)
    sigma := mod(*(—(s, r), c), n)
    U := ®(r, *(sigma, m))
    ■ U
  ```
  Solves `U ≡ r (mod m)` and `U ≡ s (mod n)` when `m` and `n` are coprime.
* **New Lean 4 / Mathlib Algorithm:**
  ```lean
  import Mathlib.Data.Int.GCD

  -- Paste into Lean 4 Web:
  def cra2 (r m s n : Int) : Option Int :=
    match modularInverse m n with
    | none => none
    | some inv =>
      let sigma := ((s - r) * inv) % n
      some (r + m * sigma)
  ```

  Mathlib also provides `Nat.chineseRemainder` / `ZMod` CRT APIs when working modulo `m * n` directly.

### Algorithm 9: Fast Fourier Transform (`FFT`)
* **Original Icon Code** [4]:
  ```icon
  FFT (N, ax, omega) <=
    local A, n, bx, cx, omega2, B, C, omegak
    if N = 1
    then ■ [0th_coef(ax)]
    else { n := N / 2
           bx := poly_of_even_powered_terms(ax)
           cx := poly_of_odd_powered_terms(ax)
           omega2 := exp(omega, 2)
           B := FFT(n, bx, omega2)
           C := FFT(n, cx, omega2)
           every k := 1 to n do
           { omegak := exp(omega, k - 1)
             A[k] := ®(B[k], *(omegak, C[k]))
             A[k + n] := —(B[k], *(omegak, C[k])) }}
    ■ A
  ```
  The report pairs this with `FFI` (Fast Fourier Interpolation); see Algorithm 15 below.
* **New Lean 4 / Mathlib Algorithm:** See [`Icon2lean/Fft.lean`](Icon2lean/Fft.lean) — `evenTerms`, `oddTerms`, and `fftCoeffs` (no `sorry`).
  ```lean
  import Icon2lean.Fft

  open Icon2lean Polynomial

  -- Illustrative: FFT decimation on Q
  #eval fftCoeffs 4 (C (1 : Rat) + X + X ^ 2 + X ^ 3) (1 : Rat)
  ```

### Algorithm 10: Newton Power Series Inversion (`NPSI`)
* **Original Icon Code** [4]:
  ```icon
  NPSI (at) <=
    local ax, xt, n
    ax := at.poly
    xt := poly_of(0th_coef(ax))
    n := log2(*ax.terms)
    every k := 0 to n - 1 do
      xt := —(*(xt, xt), *(truncate(ax, 2 ^ (k + 1)), *(xt, xt)))
    ■ tpower(truncate(xt, at.N), at.N)
  ```
  Each iteration doubles the number of correct inverse coefficients (Newton iteration on `1/a`).
* **New Lean 4 / Mathlib Algorithm:**
  ```lean
  import Mathlib.Algebra.Polynomial.Basic

  open Polynomial

  -- One doubling step: x ↦ x * (2 - a*x)  (mod X^deg)
  -- Paste into Lean 4 Web:
  def npsiStep [CommRing R] [DecidableEq R] (a x : Polynomial R) (deg : Nat) : Polynomial R :=
    let ax := (a * x) % (X ^ deg)
    (x * (C 2 - ax)) % (X ^ deg)

  -- Repeat `npsiStep` with doubling precision, as in the report's `every k := 0 to n - 1`.
  partial def npsi [CommRing R] [DecidableEq R] (a : Polynomial R) (N : Nat) (steps : Nat) : Polynomial R :=
    let rec go (k : Nat) (x : Polynomial R) : Polynomial R :=
      if k = steps then x % (X ^ N)
      else go (k + 1) (npsiStep a x (2 ^ (k + 1)))
    go 0 (C (a.coeff 0))
  ```

### Algorithm 11: Linear Diophantine Equation (`DIOPHANTINE`)
* **Original Icon Code** [4]:
  ```icon
  DIOPHANTINE (a, b, c) <=
    local gst, g, x1, y1
    gst := EUCLID(a, b)
    g := gst[1]
    if not |(g, c) then pr{"ERROR: Diophantine solution nonexistent"}
    else { if <(abs(b), abs(a))
           then { x1 := CRA1(a, c, abs(b))
                  y1 := ©(—(c, *(a, x1)), b) }
           else { y1 := CRA1(b, c, abs(a))
                  x1 := ©(—(c, *(b, y1)), a) }
           ■ [g, x1, y1] }
  ```
  The report returns one particular solution `[g, x1, y1]` via `CRA1`; Bézout coefficients give the same information more directly.
* **New Lean 4 / Mathlib Algorithm:**
  ```lean
  import Mathlib.Data.Int.GCD

  -- Paste into Lean 4 Web:
  structure DiophantineSolution where
    g : Nat
    x0 : Int
    y0 : Int

  def solveDiophantine (a b c : Int) : Option DiophantineSolution :=
    let g := Int.gcd a b
    if c % (g : Int) = 0 then
      let k := c / (g : Int)
      some { g := g, x0 := Int.gcdA a b * k, y0 := Int.gcdB a b * k }
    else
      none
  ```

### Algorithm 12: Single Linear Congruence (`CRA1`)
* **Original Icon Code** [4]:
  ```icon
  CRA1 (aa, bb, m) <=
    local a, b, g
    g := GCD(aa, m)
    if not |(g, bb) then pr{"ERROR: no solution to linear congruence"}
    else { a := mod(aa, m); b := mod(bb, m)
           if =(a, 1(a)) then b
           else if =(b, 0(b)) then 0(b)
           else if =(a, b) then inverse(b)
           else div(add(mul(m, CRA1(m, -(b), a)), b), a) }
  ```
* **Lean 4:** [`Icon2lean/Congruence.lean`](Icon2lean/Congruence.lean) — `cra1`

### Algorithm 13: N-Way Chinese Remainder (`CRA`)
* **Original Icon Code** [4]:
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
* **Lean 4:** [`Icon2lean/Congruence.lean`](Icon2lean/Congruence.lean) — `cra`
  ```lean
  import Icon2lean.Congruence

  -- Report example: some 868
  #eval Icon2lean.cra [(1, 3), (3, 5), (0, 7), (10, 11)]
  ```

### Algorithm 14: Subresultant PRS (`S_PRS`)
* **Original Icon Code** [4]: Collins–Brown subresultant sequence (report §3.2.4).
* **Lean 4:** [`Icon2lean/Polynomial.lean`](Icon2lean/Polynomial.lean) — `sPRS`

### Algorithm 15: Fast Fourier Interpolation (`FFI`)
* **Original Icon Code** [4]:
  ```icon
  FFI (N, B, omega) <=
    local bx, C, ax
    bx := polynomialize(B)
    C := FFT(N, bx, inverse(omega))
    ax := polynomialize(scalarVector(C, inverse(N)))
    ■ ax
  ```
* **Lean 4:** [`Icon2lean/Fft.lean`](Icon2lean/Fft.lean) — `ffi`

---

## Building and testing the Lean port

From the repository root (requires [Lean 4](https://lean-lang.org/) via `elan`):

```bash
lake update   # first time only — downloads Mathlib
lake build    # typechecks all algorithms; no sorry
```

Module map:

| Report algorithm | Lean module | Main definition |
|----------------|-------------|-----------------|
| `GCD`, `EUCLID`, `INVERSE` | `Icon2lean/Gcd.lean` | `gcdInt`, `euclidInt`, `modularInverse` |
| `CRA1`, `CRA2`, `CRA` | `Icon2lean/Congruence.lean` | `cra1`, `cra2`, `cra` |
| `DIOPHANTINE` | `Icon2lean/Diophantine.lean` | `solveDiophantine` |
| `PREM`, `MOD_RS`, `E_PRS`, `S_PRS` | `Icon2lean/Polynomial.lean` | `prem`, `modRS`, `ePRS`, `sPRS` |
| `NIA` | `Icon2lean/Interpolation.lean` | `newtonInterpolation` |
| `FFT`, `FFI` | `Icon2lean/Fft.lean` | `fftCoeffs`, `ffi` |
| `NPSI` | `Icon2lean/PowerSeries.lean` | `npsi`, `npsiTpower` |
| Domain types | `Icon2lean/Types.lean` | `BaseB`, `TPower`, `truncateTo` |

Checked examples against the report live in [`Icon2lean/Tests.lean`](Icon2lean/Tests.lean) (`CRA2` → 48, `CRA` → 868, `INVERSE 30 mod 197` → 46).

## Conclusion: From Operational Success to Formal Proof

The transition of this codebase from 1986 Icon to Lean 4 highlights the profound evolution of computer algebra.

In 1986, we called our technical reports and codebase "experimental" [1, 2]. We evaluated our algorithms on selected inputs and checked the output to declare empirical success [2]. However, there was no way to prove that our GCD or FFT code would behave correctly under all possible boundary conditions [2].

Four decades later, Lean 4 and Mathlib 4 present a different standard.

When we translate these algorithms into Lean, we are no longer just coding—we are formalizing mathematics. The compiler requires us to prove the mathematical invariants of our custom types and verify that recursions terminate before the code will even compile. Brittle, string-based runtime dispatch has been replaced by typeclass resolution that mathematically ensures safety [2]. What was once an experimental prototype is now a formally verified framework.

---
### References
* [1] Lars Warren Ericson, *"An ICON Package for Experimenting with Euclidean Domains"*, New York University Department of Computer Science Technical Report #232, August 1986. ([`Courant_Ericson_1986.md`](Courant_Ericson_1986.md))
* [2] Technical Report #232, Section 1: *Introduction & Programming with Euclidean Domains*.
* [3] Technical Report #232, Section 2: *Euclidean domains: representation and basic arithmetic*.
* [4] Technical Report #232, Section 3: *Algorithms for various problems over Euclidean domains*.
