/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Icon2lean.Congruence
import Icon2lean.ComputablePoly
import Icon2lean.Diophantine
import Icon2lean.Gcd

/-!
Report §3 worked examples. Integer algorithms (§3.1) use `native_decide`.
Polynomial sequences (§3.2) use the computable `CompPoly` layer because
Mathlib's `Polynomial Rat` is noncomputable for `#eval` / `native_decide`.
-/

set_option linter.style.nativeDecide false

open Icon2lean CompPoly CRat

namespace Icon2lean.Tests

section Gcd

/-- Report §3.1.1 extended gcd table (machine integers). -/
example : euclidInt 84 54 = (6, 2, -3) := by native_decide

end Gcd

section Congruence

example : cra1 7 1432 5317 = some 4762 := by native_decide
example : cra1 863 880 2151 = some 173 := by native_decide
example : cra1 589 509 817 = none := by native_decide
example : cra2 6 7 3 9 = some 48 := by native_decide
example : cra [(1, 3), (3, 5), (0, 7), (10, 11)] = some 868 := by native_decide

end Congruence

section Diophantine

example : (diophantine 84 54 (-24)).map (fun s => (s.x0, s.y0)) = some (1, -2) := by
  native_decide

example : (diophantine 999 (-49) 5000).map (fun s => (s.x0, s.y0)) = some (13, 163) := by
  native_decide

example : (diophantine 247 589 817).map (fun s => (s.x0, s.y0)) = some (-11, 6) := by
  native_decide

end Diophantine

section Polynomial

/-- Report §3.2.1 inputs: `2 - x + 3x² + 2x⁴ + x⁵` and `2 - x + 3x³`. -/
def modRsAx : CompPoly := ofInts [2, -1, 3, 0, 2, 1]

def modRsBx : CompPoly := ofInts [2, -1, 0, 3]

def c16_9 : CRat := CRat.normalize { num := 16, den := 9 }
def c20_9 : CRat := CRat.normalize { num := -20, den := 9 }
def c166_243 : CRat := CRat.normalize { num := 166, den := 243 }
def c275_243 : CRat := CRat.normalize { num := -275, den := 243 }

def modRsSeq : List CompPoly := modRS modRsAx modRsBx

example : modRsSeq.length = 6 := by native_decide

example : modRsSeq.getLast!.isZero := by native_decide

example : getCoeff modRsSeq[2]! 0 = c16_9 := by native_decide
example : getCoeff modRsSeq[2]! 1 = c20_9 := by native_decide
example : getCoeff modRsSeq[2]! 2 = CRat.ofInt 3 := by native_decide
example : getCoeff modRsSeq[3]! 0 = c166_243 := by native_decide
example : getCoeff modRsSeq[3]! 1 = c275_243 := by native_decide

/-- Report §3.2.2 `PREM` inputs. Field pseudo-remainder (matches `Icon2lean.Polynomial.prem`). -/
def premP : CompPoly := ofInts [22, -1, 3, 0, 22, 0, 1]
def premQ : CompPoly := ofInts [2, -1, 0, 3]

example : getCoeff (prem premP premQ) 0 = CRat.ofInt 1818 := by native_decide
example : getCoeff (prem premP premQ) 1 = CRat.ofInt (-1305) := by native_decide
example : getCoeff (prem premP premQ) 2 = CRat.ofInt 846 := by native_decide

-- Click any `#eval` below — Infoview shows the computed report value.
#eval euclidInt 84 54
#eval cra2 6 7 3 9
#eval cra [(1, 3), (3, 5), (0, 7), (10, 11)]
#eval diophantine 84 54 (-24) |>.map (fun s => (s.x0, s.y0))
#eval modRsSeq.length
#eval (getCoeff modRsSeq[2]! 0, getCoeff modRsSeq[2]! 1, getCoeff modRsSeq[2]! 2)
#eval prem premP premQ |>.coeffs

end Polynomial

end Icon2lean.Tests
