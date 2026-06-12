/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Icon2lean.Types
import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Algebra.Polynomial.Div

namespace Icon2lean

open Polynomial

/-- One Newton step for truncated power-series inversion (report §3.3.3). -/
noncomputable def npsiStep {R : Type*} [CommRing R] [DecidableEq R]
    (a x : Polynomial R) (deg : Nat) : Polynomial R :=
  let ax := (a * x) %ₘ (X ^ deg)
  (x * (C 2 - ax)) %ₘ (X ^ deg)

/-- Newton power-series inversion to precision `N` with `steps` doublings (report §3.3.3 `NPSI`). -/
noncomputable def npsi {R : Type*} [CommRing R] [DecidableEq R]
    (a : Polynomial R) (N steps : Nat) : Polynomial R :=
  let rec go (fuel k : Nat) (x : Polynomial R) : Polynomial R :=
    if k = steps ∨ fuel = 0 then x %ₘ (X ^ N)
    else go (fuel - 1) (k + 1) (npsiStep a x (2 ^ (k + 1)))
  go steps 0 (C (a.coeff 0))

/-- `NPSI` on a polynomial representative at truncation degree `N`. -/
noncomputable def npsiTrunc {R : Type*} [CommRing R] [DecidableEq R]
    (p : Polynomial R) (N steps : Nat) : Polynomial R :=
  npsi p N steps

/-- `NPSI` as an element of `TruncPowerSeries R N`. -/
noncomputable def npsiTruncQuotient {R : Type*} [CommRing R] [DecidableEq R]
    (p : Polynomial R) (N steps : Nat) : TruncPowerSeries R N :=
  truncMk N (npsi p N steps)

end Icon2lean
