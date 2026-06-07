/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Algebra.Polynomial.Div
import Mathlib.Algebra.Polynomial.Degree.Defs
import Mathlib.Algebra.Polynomial.FieldDivision

namespace Icon2lean

open Polynomial

/-- Pseudo-remainder (report §3.2.2 `PREM`). -/
noncomputable def prem [Field R] [DecidableEq R] (p q : Polynomial R) : Polynomial R :=
  if q = 0 then p
  else
    let d := max 0 (p.natDegree - q.natDegree)
    let b := q.leadingCoeff
    (C (b ^ (d + 1)) * p) % q

private noncomputable def modRS.go [Field R] [DecidableEq R] :
    Nat → Polynomial R → Polynomial R → List (Polynomial R)
  | 0, a, _ => [a]
  | fuel + 1, a, b =>
    if b = 0 then [a]
    else a :: modRS.go fuel b (a % b)

/-- MOD-based polynomial remainder sequence (report §3.2.1 `MOD_RS`). -/
noncomputable def modRS [Field R] [DecidableEq R] (a b : Polynomial R) : List (Polynomial R) :=
  modRS.go (a.natDegree + b.natDegree + 1) a b

private noncomputable def ePRS.go [Field R] [DecidableEq R] :
    Nat → Polynomial R → Polynomial R → List (Polynomial R)
  | 0, a, _ => [a]
  | fuel + 1, a, b =>
    if b = 0 then [a]
    else a :: ePRS.go fuel b (prem a b)

/-- PREM-based PRS (report §3.2.3 `E_PRS`). -/
noncomputable def ePRS [Field R] [DecidableEq R] (a b : Polynomial R) : List (Polynomial R) :=
  ePRS.go (a.natDegree + b.natDegree + 1) a b

private noncomputable def subDelta [Field R] [DecidableEq R] (p q : Polynomial R) : Nat :=
  max 0 (p.natDegree - q.natDegree)

private noncomputable def subBeta [Field R] [DecidableEq R] (p q : Polynomial R) : R :=
  (-p.leadingCoeff) ^ subDelta p q

private noncomputable def subReduce [Field R] [DecidableEq R] (p q : Polynomial R) : Polynomial R :=
  let r := prem p q
  let β := subBeta p q
  if β = 0 then r else r / C β

private noncomputable def sPRS.go [Field R] [DecidableEq R] :
    Nat → List (Polynomial R) → Polynomial R → Polynomial R → List (Polynomial R)
  | 0, acc, _, _ => acc
  | fuel + 1, acc, pPrev, pCurr =>
    if pCurr = 0 then acc
    else
      let next := subReduce pPrev pCurr
      if next = 0 then acc ++ [pCurr]
      else sPRS.go fuel (acc ++ [pCurr]) pCurr next

/-- Subresultant PRS (Collins–Brown, report §3.2.4 `S_PRS`). -/
noncomputable def sPRS [Field R] [DecidableEq R] (p q : Polynomial R) : List (Polynomial R) :=
  if q = 0 then [p]
  else
    let p2 := subReduce p q
    if p2 = 0 then [p, q]
    else sPRS.go (p.natDegree + q.natDegree + 1) [p, q] q p2

end Icon2lean
