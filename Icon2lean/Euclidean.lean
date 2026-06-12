/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Mathlib.Algebra.EuclideanDomain.Basic
import Mathlib.Algebra.EuclideanDomain.Defs
import Mathlib.Algebra.EuclideanDomain.Int
import Mathlib.Data.Int.GCD

/-!
# Generic Euclidean-domain algorithms (report §3.1)

Algorithms are stated once against the `EuclideanDomain` typeclass (proof / canonical layer).
Concrete types (`ℤ`, `ℚ`, `ZMod p`, `Polynomial F`) supply instances; computability is per-type:

| Domain | Eval / `native_decide` |
|--------|-------------------------|
| `ℤ` | direct (kernel arithmetic) |
| `ZMod p` | `decide` for small `p` |
| `Polynomial ℚ` | `CompPoly` mirror — see `ComputablePoly.lean` |
| `TruncPowerSeries ℚ n` | `CompTPS` mirror — see `ComputableTPS.lean` |
-/

namespace Icon2lean

noncomputable section Generic

variable {α : Type*} [EuclideanDomain α] [DecidableEq α]

/-- Greatest common divisor (report §3.1.1 `GCD`). -/
noncomputable def euclideanGcd (a b : α) : α :=
  EuclideanDomain.gcd a b

/-- Extended Euclidean algorithm (report §3.1.1 `EUCLID`): `(g, s, t)` with `g = s * a + t * b`. -/
noncomputable def euclid (a b : α) : α × α × α :=
  (euclideanGcd a b, EuclideanDomain.gcdA a b, EuclideanDomain.gcdB a b)

theorem euclid_bezout (a b : α) :
    euclideanGcd a b = a * EuclideanDomain.gcdA a b + b * EuclideanDomain.gcdB a b :=
  EuclideanDomain.gcd_eq_gcd_ab a b

end Generic

/-! ### `ℤ` — computable tests without a mirror type -/

/-- Modular inverse in `ℤ/(m)` when it exists (report §3.1.2 `INVERSE`). -/
def modularInverse (a m : ℤ) : Option ℤ :=
  let g := Int.gcd m a
  if g = 1 then
    some (Int.emod (Int.gcdB m a / (g : ℤ)) m)
  else
    none

/-- Computable extended gcd on `ℤ` (kernel reduction; same coefficients as `euclid`). -/
def euclidZ (A B : ℤ) : ℤ × ℤ × ℤ :=
  ((Int.gcd A B : ℤ), Int.gcdA A B, Int.gcdB A B)

/-- Report-style `EUCLID` on `ℤ` using kernel `Int.gcd` (gcd returned as `ℕ`). -/
def euclidInt (A B : ℤ) : Nat × ℤ × ℤ :=
  (Int.gcd A B, Int.gcdA A B, Int.gcdB A B)

theorem euclidInt_bezout (A B : ℤ) :
    (Int.gcd A B : ℤ) = A * Int.gcdA A B + B * Int.gcdB A B :=
  Int.gcd_eq_gcd_ab A B

theorem euclidZ_bezout (A B : ℤ) :
    (euclidZ A B).1 = A * (euclidZ A B).2.1 + B * (euclidZ A B).2.2 := by
  simpa [euclidZ] using euclidInt_bezout A B

end Icon2lean
