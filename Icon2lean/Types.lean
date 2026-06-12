/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Algebra.Polynomial.Div
import Mathlib.Data.ZMod.Basic
import Mathlib.RingTheory.Ideal.Quotient.Basic
import Mathlib.RingTheory.Ideal.Span

/-!
# Domain constructors (report §2)

The 1986 report's **quotient Euclidean domain** is a **Euclidean domain** in modern Mathlib.
Three domain *constructors* build new rings from a coefficient domain:

| Constructor | Report | Lean type |
|-------------|--------|-----------|
| modular | `modulo(item, modulus)` — `D/(e)` | `ModularDomain R I` or `ModularInt n` |
| polynomial | `poly(terms)` — `D[x]` | `PolyDomain R` (= `Polynomial R`) |
| truncated power series | `tpower(poly, N)` — `T(D[[x]])ₙ` | `TruncPowerSeries R n` |

Primitive coefficient domains used in the report: `ℤ`, `ℚ`. Integer literals use base 10
by convention; no separate base-`B` type is needed for the algorithms in §3.
-/

namespace Icon2lean

open Polynomial

/-! ## Modular domain `D/(e)` -/

/-- Modular domain: quotient of a commutative ring by an ideal (`D ⧸ I`). -/
abbrev ModularDomain (R : Type*) [CommRing R] (I : Ideal R) := R ⧸ I

/-- Integer modular domain `ℤ/(n)` (report `modulo` with integer coefficients). -/
abbrev ModularInt (n : ℕ) := ZMod n

/-! ## Polynomial domain `D[x]` -/

/-- Polynomial domain over coefficient ring `R` (report `poly`). -/
abbrev PolyDomain (R : Type*) [Semiring R] := Polynomial R

/-! ## Truncated power series `T(D[[x]])ₙ` -/

/-- The ideal `(Xⁿ)` in `R[x]`; arithmetic mod `Xⁿ` is the paper's `truncate`. -/
noncomputable def truncIdeal (R : Type*) [CommRing R] (n : ℕ) : Ideal (Polynomial R) :=
  Ideal.span {(X : Polynomial R) ^ n}

/-- Truncated power series ring `R[x]/(Xⁿ)` (report `tpower` at fixed precision `n`). -/
noncomputable abbrev TruncPowerSeries (R : Type*) [CommRing R] (n : ℕ) :=
  Polynomial R ⧸ truncIdeal R n

/-- Reduce a polynomial to its first `n` terms (`truncate` in the report). -/
noncomputable def truncatePoly {R : Type*} [CommRing R] (n : ℕ) (p : Polynomial R) : Polynomial R :=
  p %ₘ (X ^ n)

/-- Embed a polynomial into `TruncPowerSeries R n`. -/
noncomputable def truncMk {R : Type*} [CommRing R] (n : ℕ) (p : Polynomial R) :
    TruncPowerSeries R n :=
  Ideal.Quotient.mk (truncIdeal R n) p

end Icon2lean
