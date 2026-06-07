/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Mathlib.Data.List.Basic
import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Algebra.Polynomial.Div

namespace Icon2lean

open Polynomial

/-- Unsigned base-`B` digit list (report §2.2.1 `base_b`). -/
structure BaseB (B : Nat) where
  digits : List Nat
  h_digits : ∀ d ∈ digits, d < B
  h_base : 1 < B

/-- Report §2.2.2 example: `baseB(10, [5, 3, 3, 5])`. -/
def base10_5335 : BaseB 10 := {
  digits := [5, 3, 3, 5]
  h_digits := by decide
  h_base := by decide
}

/-- Truncated power series (report §2.3.4 `tpower`). -/
structure TPower (R : Type*) [CommRing R] where
  poly : Polynomial R
  N : Nat

noncomputable def truncateTo {R : Type*} [CommRing R] (N : Nat) (p : Polynomial R) : Polynomial R :=
  p %ₘ (X ^ N)

noncomputable def tpowerMk {R : Type*} [CommRing R] (p : Polynomial R) (N : Nat) : TPower R :=
  { poly := truncateTo N p, N := N }

end Icon2lean
