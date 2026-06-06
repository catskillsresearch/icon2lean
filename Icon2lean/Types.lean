import Mathlib.Data.List.Basic
import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Algebra.Polynomial.Div

namespace Icon2lean

open Polynomial

/-- Unsigned base-`B` digit list (report §2.2.1). -/
structure BaseB (B : Nat) where
  digits : List Nat
  h_digits : ∀ d ∈ digits, d < B
  h_base : 1 < B

def base8_one : BaseB 8 := {
  digits := [1]
  h_digits := by decide
  h_base := by decide
}

/-- Truncated power series: polynomial plus truncation degree (report §2.3.4). -/
structure TPower (R : Type*) [CommRing R] where
  poly : Polynomial R
  N : Nat

noncomputable def truncateTo {R : Type*} [CommRing R] (N : Nat) (p : Polynomial R) : Polynomial R :=
  p %ₘ (X ^ N)

noncomputable def tpowerMk {R : Type*} [CommRing R] (p : Polynomial R) (N : Nat) : TPower R :=
  { poly := truncateTo N p, N := N }

end Icon2lean
