/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Icon2lean.Congruence
import Icon2lean.ComputableAlg
import Icon2lean.ComputablePoly
import Icon2lean.ComputableTPS
import Icon2lean.Diophantine
import Icon2lean.Euclidean

/-!
Report §3 + §2 benchmark parity with [`tests.icn`](../../tests.icn).

* `ℤ`, `ZMod p`, congruence, Diophantine: kernel `native_decide`
* `ℚ[x]`, truncated series: `CompPoly` / `CompTPS` mirrors

Run all printed values:

```bash
lake build Icon2lean.Tests 2>&1 | grep "^info: Icon2lean/Tests"
```
-/

set_option linter.style.nativeDecide false

open Icon2lean CompPoly CRat CompTPS ModPoly

namespace Icon2lean.Tests

/-! ### helpers -/

def crat (num den : Int) : CRat := CRat.normalize { num := num, den := Int.natAbs den }

def c5_9 : CRat := crat 5 9
def c16_9 : CRat := crat 16 9
def c20_9 : CRat := crat (-20) 9
def c166_243 : CRat := crat 166 243
def c275_243 : CRat := crat (-275) 243
def c115668_75625 : CRat := crat 115668 75625

/-! ### §2 — `ℤ` arithmetic (Icon `test_Z_ops`) -/

section ZOps

example : (1 : ℤ) + (-999) = (-998 : ℤ) := by native_decide
example : -(212 : ℤ) = (-212 : ℤ) := by native_decide
example : -(-99 : ℤ) = (99 : ℤ) := by native_decide
example : (10 : ℤ) / 1 = (10 : ℤ) := by native_decide
example : (121903 : ℤ) / 5335 = (22 : ℤ) := by native_decide
example : (115668 : ℤ) / 75625 = (1 : ℤ) := by native_decide
example : (121903 : ℤ) % 5335 = (4533 : ℤ) := by native_decide

end ZOps

/-! ### §3.1.1 — `GCD` / `EUCLID` -/

section GcdEuclid

example : Int.gcd 228 612 = 12 := by native_decide
example : Int.gcd 121903 5335 = 1 := by native_decide
example : Int.gcd (-18) 5 = 1 := by native_decide

example : euclidInt 84 54 = (6, 2, -3) := by native_decide
example : euclidZ 84 54 = (6, 2, -3) := by native_decide
example : euclidInt 2 4 = (2, 1, 0) := by native_decide
example : euclidInt 228 612 = (12, -8, 3) := by native_decide
example : euclidInt 59 24 = (1, 11, -27) := by native_decide

def gcdQxA : CompPoly := ofInts [-2, 0, 0, 1]
def gcdQxB : CompPoly := ofInts [-3, 0, 2]

example : CompPoly.getCoeff (CompPoly.gcd gcdQxA gcdQxB) 0 = c5_9 := by native_decide

def gcdQzRow7A : CompPoly := { coeffs := [c166_243, c275_243] }
def gcdQzRow7B : CompPoly := { coeffs := [c115668_75625] }

example : CompPoly.getCoeff (CompPoly.gcd gcdQzRow7A gcdQzRow7B) 0 = c115668_75625 := by native_decide

def gcdQzRow8A : CompPoly := ofInts [-2, 0, 0, 1]
def gcdQzRow8B : CompPoly := ofInts [-3, 0, 2]

example : CompPoly.getCoeff (CompPoly.gcd gcdQzRow8A gcdQzRow8B) 0 = c5_9 := by native_decide

example : ModPoly.gcd 5 (ModPoly.ofInts 5 [-2]) (ModPoly.ofInts 5 [-3]) = [1] := by native_decide

def z5xA : List Nat := ModPoly.ofInts 5 [-2, 0, 0, 1]
def z5xB : List Nat := ModPoly.ofInts 5 [-3, 0, 2]

example : ModPoly.gcd 5 z5xA z5xB = [3, 4] := by native_decide

def z5Euclid := ModPoly.euclid 5 z5xA z5xB

example : z5Euclid.1 = [3, 4] := by native_decide
example : z5Euclid.2.1 = [1] := by native_decide
example : z5Euclid.2.2 = [0, 2] := by native_decide

end GcdEuclid

/-! ### §3.1.2 — `INVERSE` -/

section Inverse

example : modularInverse 30 197 = some 46 := by native_decide
example : modularInverse 16 21 = some 4 := by native_decide
example : modularInverse 24 59 = some 32 := by native_decide
example : modularInverse 18 21 = none := by native_decide

def gf2A : List Nat := ModPoly.ofInts 2 [1, 0, 1]
def gf2B : List Nat := ModPoly.ofInts 2 [1, 0, 1, 0, 0, 1]

example : ModPoly.inverse 2 gf2A gf2B = some [1, 1, 1, 0, 1] := by native_decide

def invQxA : CompPoly := ofInts [-3, 0, 2]
def invQxB : CompPoly := ofInts [-2, 0, 0, 1]
def invQx := CompPoly.inverse invQxA invQxB

example : invQx.isSome := by native_decide
example : getCoeff invQx.get! 0 = crat 9 5 := by native_decide
example : getCoeff invQx.get! 1 = crat 8 5 := by native_decide
example : getCoeff invQx.get! 2 = crat 6 5 := by native_decide

end Inverse

/-! ### §3.1.3 — congruence / CRA -/

section Congruence

example : cra1 7 1432 5317 = some 4762 := by native_decide
example : cra1 863 880 2151 = some 173 := by native_decide
example : cra1 589 509 817 = none := by native_decide
example : cra2 6 7 3 9 = some 48 := by native_decide
example : cra [(1, 3), (3, 5), (0, 7), (10, 11)] = some 868 := by native_decide
example : cra [(1, 3), (0, 7), (2, 4), (3, 5)] = some 238 := by native_decide
example : cra [(0, 3), (1, 7), (3, 4), (3, 5)] = some 183 := by native_decide

end Congruence

/-! ### §3.1.4 — Diophantine -/

section Diophantine

example : (diophantine 84 54 (-24)).map (fun s => (s.g, s.x0, s.y0)) = some (6, 1, -2) := by
  native_decide
example : (diophantine 999 (-49) 5000).map (fun s => (s.g, s.x0, s.y0)) = some (1, 13, 163) := by
  native_decide
example : (diophantine 247 589 817).map (fun s => (s.g, s.x0, s.y0)) = some (19, -11, 6) := by
  native_decide

end Diophantine

/-! ### §3.2 — polynomial remainder sequences -/

section Polynomial

def modRsAx : CompPoly := ofInts [2, -1, 3, 0, 2, 1]
def modRsBx : CompPoly := ofInts [2, -1, 0, 3]
def modRsSeq : List CompPoly := modRS modRsAx modRsBx

example : modRsSeq.length = 6 := by native_decide
example : modRsSeq[0]! = modRsAx := by native_decide
example : modRsSeq[1]! = modRsBx := by native_decide
example : modRsSeq.getLast!.isZero := by native_decide
example : getCoeff modRsSeq[2]! 0 = c16_9 := by native_decide
example : getCoeff modRsSeq[2]! 1 = c20_9 := by native_decide
example : getCoeff modRsSeq[2]! 2 = CRat.ofInt 3 := by native_decide
example : getCoeff modRsSeq[3]! 0 = c166_243 := by native_decide
example : getCoeff modRsSeq[3]! 1 = c275_243 := by native_decide
example : getCoeff modRsSeq[4]! 0 = c115668_75625 := by native_decide

def premP : CompPoly := ofInts [2, -1, 3, 0, 2, 0, 1]
def premQ : CompPoly := ofInts [2, -1, 0, 3]

example : getCoeff (prem premP premQ) 0 = CRat.ofInt 198 := by native_decide
example : getCoeff (prem premP premQ) 1 = CRat.ofInt (-225) := by native_decide
example : getCoeff (prem premP premQ) 2 = CRat.ofInt 306 := by native_decide

def premRow2P : CompPoly := ofInts [21, -9, -4, 0, 5, 0, 3]
def premRow2Q : CompPoly := ofInts [-9, 0, 3, 0, -15]

example : getCoeff (prem premRow2P premRow2Q) 0 = CRat.ofInt (-59535) := by native_decide
example : getCoeff (prem premRow2P premRow2Q) 1 = CRat.ofInt 30375 := by native_decide
example : getCoeff (prem premRow2P premRow2Q) 2 = CRat.ofInt 15795 := by native_decide

def premRow4P : CompPoly := ofInts [198, -225, 0, 306]
def premRow4Q : CompPoly := ofInts [18, 369]

example : getCoeff (prem premRow4P premRow4Q) 0 = CRat.ofInt 10497862440 := by native_decide

def premRow5P : CompPoly := ofInts [-245, 125, 65]
def premRow5Q : CompPoly := ofInts [-12300, 9326]

example : getCoeff (prem premRow5P premRow5Q) 0 = CRat.ofInt 2863877380 := by native_decide

def eprsP0 : CompPoly := ofInts [-1, 0, 1]
def eprsP1 : CompPoly := ofInts [-1, 1]
def eprsSeq : List CompPoly := ePRS eprsP0 eprsP1

example : eprsSeq.length = 3 := by native_decide
example : eprsSeq[0]! = eprsP0 := by native_decide
example : eprsSeq[1]! = eprsP1 := by native_decide
example : eprsSeq[2]!.isZero := by native_decide

def sprsSeq : List CompPoly := sPRS eprsP0 eprsP1

example : sprsSeq.length = 2 := by native_decide
example : sprsSeq[0]! = eprsP0 := by native_decide
example : sprsSeq[1]! = eprsP1 := by native_decide

end Polynomial

/-! ### §3.3 — interpolation, FFT, power series -/

section Transforms

def niaDemo := nia [(CRat.ofInt 0, CRat.ofInt 1), (CRat.ofInt 1, CRat.ofInt 3)]

example : niaDemo.coeffs.map CRat.num = [1, 2] := by native_decide

example : fftCoeffs 2 [CRat.ofInt 1, CRat.ofInt 2] (CRat.ofInt (-1)) =
    [CRat.ofInt 3, CRat.ofInt (-1)] := by native_decide

def ffiDemo := ffi 2 [CRat.ofInt 3, CRat.ofInt (-1)] (CRat.ofInt (-1))

example : ffiDemo.coeffs.map CRat.num = [1, 2] := by native_decide

def npsiInput : CompTPS := CompTPS.ofInts 2 [1, 1]
def npsiOut : CompTPS := CompTPS.npsi npsiInput 1

example : npsiOut.coeffs = [CRat.ofInt 1, CRat.ofInt (-1)] := by native_decide
example : (CompTPS.mul npsiInput npsiOut).coeffs.getD 0 CRat.zero = CRat.ofInt 1 := by native_decide

end Transforms

/-! ### `#eval` — mirror of Icon `tests.icn` stdout (grep `^info:` after build) -/

#eval (1 : ℤ) + (-999)
#eval (121903 : ℤ) % 5335
#eval Int.gcd 121903 5335
#eval euclidInt 2 4
#eval euclidInt 84 54
#eval diophantine 999 (-49) 5000
#eval eprsSeq.map (·.coeffs)
#eval sprsSeq.map (·.coeffs)
#eval getCoeff (prem premRow4P premRow4Q) 0
#eval getCoeff (prem premRow5P premRow5Q) 0
#eval euclidInt 228 612
#eval euclidInt 59 24
#eval modularInverse 30 197
#eval invQx
#eval ModPoly.inverse 2 gf2A gf2B
#eval CompPoly.gcd gcdQxA gcdQxB |>.coeffs
#eval ModPoly.gcd 5 z5xA z5xB
#eval z5Euclid
#eval cra2 6 7 3 9
#eval cra [(1, 3), (3, 5), (0, 7), (10, 11)]
#eval cra [(1, 3), (0, 7), (2, 4), (3, 5)]
#eval cra [(0, 3), (1, 7), (3, 4), (3, 5)]
#eval diophantine 84 54 (-24)
#eval diophantine 247 589 817
#eval modRsSeq.length
#eval (getCoeff modRsSeq[2]! 0, getCoeff modRsSeq[2]! 1, getCoeff modRsSeq[2]! 2)
#eval prem premP premQ |>.coeffs
#eval getCoeff (prem premRow2P premRow2Q) 0
#eval eprsSeq.map (·.coeffs)
#eval sprsSeq.map (·.coeffs)
#eval niaDemo.coeffs
#eval fftCoeffs 2 [CRat.ofInt 1, CRat.ofInt 2] (CRat.ofInt (-1))
#eval ffiDemo.coeffs
#eval npsiOut.coeffs

end Icon2lean.Tests
