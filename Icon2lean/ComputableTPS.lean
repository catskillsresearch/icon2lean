/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Icon2lean.ComputablePoly
import Icon2lean.Types
import Mathlib.Algebra.Polynomial.Basic

/-!
Computable truncated power series `R[x]/(X^N)` for `#eval` / `native_decide`.

Canonical (proof) type: `TruncPowerSeries R N` in `Types.lean`.
Coherence: `CompTPS.toMathlib` is the sole boundary map into the quotient type.
-/

namespace Icon2lean

open Polynomial

/-- Truncated power series at precision `N`: dense coefficient list, index = degree. -/
structure CompTPS where
  N : Nat
  coeffs : List CRat
deriving DecidableEq, Repr, Inhabited

namespace CompTPS

def ofInts (N : Nat) (cs : List Int) : CompTPS :=
  { N := N, coeffs := cs.map CRat.ofInt }

def pad (t : CompTPS) : CompTPS :=
  if t.coeffs.length ≥ t.N then { t with coeffs := t.coeffs.take t.N }
  else { t with coeffs := t.coeffs ++ List.replicate (t.N - t.coeffs.length) CRat.zero }

def getCoeff (t : CompTPS) (i : Nat) : CRat :=
  if i < t.N then t.coeffs.getD i CRat.zero else CRat.zero

def add (a b : CompTPS) : CompTPS :=
  let a' := pad a
  let b' := pad b
  let N := a'.N
  let rec build (fuel i : Nat) (acc : List CRat) : List CRat :=
    if fuel = 0 then acc.reverse
    else build (fuel - 1) (i + 1) (CRat.add (getCoeff a' i) (getCoeff b' i) :: acc)
  pad { N := N, coeffs := build N 0 [] }

def neg (t : CompTPS) : CompTPS :=
  { t with coeffs := t.coeffs.map CRat.neg }

def sub (a b : CompTPS) : CompTPS :=
  add a (neg b)

/-- Convolution product, truncated to `N` terms (report `⊗_tpower`). -/
def mul (a b : CompTPS) : CompTPS :=
  let a' := pad a
  let b' := pad b
  let N := a'.N
  let rec coeffAt (k : Nat) : CRat :=
    (List.range (min (k + 1) N)).foldl (fun acc i =>
      if k - i < N then
        CRat.add acc (CRat.mul (getCoeff a' i) (getCoeff b' (k - i)))
      else acc) CRat.zero
  let rec build (fuel k : Nat) (acc : List CRat) : List CRat :=
    if fuel = 0 then acc.reverse
    else build (fuel - 1) (k + 1) (coeffAt k :: acc)
  pad { N := N, coeffs := build N 0 [] }

/-- One Newton step: `x ↦ x * (2 - a * x)` truncated (report `NPSI` step). -/
def npsiStep (a x : CompTPS) : CompTPS :=
  let a' := pad a
  let x' := pad x
  let two := pad { N := a'.N, coeffs := [CRat.ofInt 2] }
  mul x' (sub two (mul a' x'))

/-- Newton power-series inversion (`NPSI`) in the computable layer. -/
def npsi (a : CompTPS) (steps : Nat) : CompTPS :=
  let a' := pad a
  let init := pad { N := a'.N, coeffs := [CRat.inv (getCoeff a' 0)] }
  let rec go (fuel k : Nat) (x : CompTPS) : CompTPS :=
    if k = steps ∨ fuel = 0 then pad x
    else go (fuel - 1) (k + 1) (npsiStep a' (pad x))
  go steps 0 init

/-- Embed into `Polynomial ℚ` (representative, not quotient-normalized). -/
noncomputable def toPoly (t : CompTPS) : Polynomial ℚ :=
  (List.range t.N).foldl (fun acc i =>
    acc + Polynomial.C (CRat.toRat (getCoeff t i)) * Polynomial.X ^ i) 0

/-- Boundary map into the canonical truncated series type. -/
noncomputable def toMathlib (t : CompTPS) : TruncPowerSeries ℚ t.N :=
  truncMk t.N (toPoly t)

/-!
### Coherence targets (to prove)

* `toMathlib (mul a b) = (toMathlib a) * (toMathlib b)` in `TruncPowerSeries ℚ N`
* `toMathlib (npsi a steps)` matches `npsiTruncQuotient (toPoly a) a.N steps`
-/

end CompTPS

end Icon2lean
