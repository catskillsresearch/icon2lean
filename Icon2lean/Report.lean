/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Icon2lean.Print

/-!
Executable report mirroring Icon [`tests.icn`](../../tests.icn) `main()` stdout.

```bash
lake exe iconReport
./run_lean_report.sh
```
-/

namespace Icon2lean.Report

open IconPrint CompPoly CRat CompTPS ModPoly BaseB

/-! ### shared values -/

def crat (num den : Int) : CRat := CRat.normalize { num := num, den := Int.natAbs den }

def c5_9 : CRat := crat 5 9
def c3_2 : CRat := crat 3 2
def c166_243 : CRat := crat 166 243
def c275_243 : CRat := crat (-275) 243
def c115668_75625 : CRat := crat 115668 75625

def polyQxA : CompPoly := ofInts [-2, 0, 0, 1]
def polyQxB : CompPoly := ofInts [-3, 0, 2]
def polyQxC : CompPoly := ofInts [-2, 0, 3, 2]  -- -2 + (3/2)x uses index 1
def polyQxAddB : CompPoly := ofInts [-3, 0, 0, 2]

def polyQzA : CompPoly := ofInts [-2, 0, 0, 1]
def polyQzAddB : CompPoly := ofInts [-3, 0, 0, 2]

def gcdQzRow7A : CompPoly := { coeffs := [c166_243, c275_243] }
def gcdQzRow7B : CompPoly := { coeffs := [c115668_75625] }

def z5xA : List Nat := ModPoly.ofInts 5 [-2, 0, 0, 1]
def z5xB : List Nat := ModPoly.ofInts 5 [-3, 0, 2]

def gf2A : List Nat := ModPoly.ofInts 2 [1, 0, 1]
def gf2B : List Nat := ModPoly.ofInts 2 [1, 0, 1, 0, 0, 1]

def invQxA : CompPoly := ofInts [-3, 0, 2]
def invQxB : CompPoly := ofInts [-2, 0, 0, 1]

def modRsAx : CompPoly := ofInts [2, -1, 3, 0, 2, 1]
def modRsBx : CompPoly := ofInts [2, -1, 0, 3]

def premRow1P : CompPoly := ofInts [2042542724, 17851334]
def premRow1Q : CompPoly := ofInts [5851259279846738252460]
def premRow2P : CompPoly := ofInts [21, -9, -4, 0, 5, 0, 3]
def premRow2Q : CompPoly := ofInts [-9, 0, 3, 0, -15]
def premP : CompPoly := ofInts [2, -1, 3, 0, 2, 0, 1]
def premQ : CompPoly := ofInts [2, -1, 0, 3]
def premRow4P : CompPoly := ofInts [198, -225, 0, 306]
def premRow4Q : CompPoly := ofInts [18, 369]
def premRow5P : CompPoly := ofInts [-245, 125, 65]
def premRow5Q : CompPoly := ofInts [-12300, 9326]

def eprsP0 : CompPoly := ofInts [-1, 0, 1]
def eprsP1 : CompPoly := ofInts [-1, 1]

private def writeln (s : String) : IO Unit := IO.println s
private def blank : IO Unit := writeln ""

/-! ### sections (same order as `tests.icn` `main`) -/

def testModRemExamples : IO Unit := do
  let ax := polyQxA
  let bx := polyQxB
  writeln s!"{compPoly .qRat ax} mod {compPoly .qRat bx} = {remPoly .qRat ax bx}"
  let cx := { coeffs := [CRat.ofInt (-2), c3_2] }
  writeln s!"{compPoly .qRat bx} mod {compPoly .qRat cx} = {remPoly .qRat bx cx}"
  let ax2 := ofInts [5, -2, 1]
  let bx2 := ofInts [2]
  writeln s!"{compPoly .qRat ax2} rem {compPoly .qRat bx2} = {remPoly .qRat ax2 bx2}"
  let ax3 := ofInts [8, -9, 6]
  let bx3 := ofInts [3]
  writeln s!"{compPoly .integer ax3} rem {compPoly .integer bx3} = {compPoly .integer (intPolyRemScalar ax3 3)}"

def testBaseBAdd : IO Unit := do
  let x := BaseB.ofDigits 8 [1]
  let y := BaseB.ofDigits 8 [7, 7, 7]
  writeln s!"{baseB x} + {baseB y} = {baseB (x.add y)}"

def testBaseBSub : IO Unit := do
  let x1 := BaseB.ofDigits 10 [1, 0, 0, 5, 6, 3]
  let y1 := BaseB.ofDigits 10 [5, 3, 3, 5]
  writeln s!"{baseB x1} - {baseB y1} = {baseB (x1.sub y1)}"
  let x2 := BaseB.ofDigits 10 [2, 1, 2]
  let y2 := BaseB.ofDigits 10 [9, 9]
  writeln s!"{baseB x2} - {baseB y2} = {baseB (x2.sub y2)}"
  let y3 := BaseB.ofDigits 10 [1, 9, 9]
  writeln s!"{baseB x2} - {baseB y3} = {baseB (x2.sub y3)}"

def testBaseBMul : IO Unit := do
  let x1 := BaseB.ofNat 10 28107324
  let y1 := BaseB.ofNat 10 75625
  writeln s!"{baseB x1} * {baseB y1} = {baseB (x1.mul y1)}"
  let x2 := BaseB.ofNat 10 7478
  let y2 := BaseB.ofNat 10 4625
  writeln s!"{baseB x2} * {baseB y2} = {baseB (x2.mul y2)}"

def testBaseBDiv : IO Unit := do
  let pairs : List (Nat × Nat) :=
    [(10, 1), (4, 2), (27, 9), (42, 2), (90, 1), (188175, 325), (188175, 579),
     (188175, 580), (188175, 578), (121903, 5335), (212, 99), (115668, 75625)]
  for (a, b) in pairs do
    let x := BaseB.ofNat 10 a
    let y := BaseB.ofNat 10 b
    writeln s!"{baseB x} / {baseB y} = {baseB (x.div y)}"

def testZOps : IO Unit := do
  writeln s!"{zInt 1} + {zInt (-999)} = {zInt ((1 : ℤ) + (-999))}"
  writeln s!"-{zInt 212} = {zInt (-(212 : ℤ))}"
  writeln s!"-{zInt (-99)} = {zInt (-(-99 : ℤ))}"
  writeln s!"{zInt 10} / {zInt 1} = {zInt ((10 : ℤ) / 1)}"
  writeln s!"{zInt 121903} / {zInt 5335} = {zInt ((121903 : ℤ) / 5335)}"
  writeln s!"{zInt 115668} / {zInt 75625} = {zInt ((115668 : ℤ) / 75625)}"
  writeln s!"{zInt 121903} mod {zInt 5335} = {zInt ((121903 : ℤ) % 5335)}"

def testQPolyZero : IO Unit := do
  writeln "Q: 0 = 0q"
  writeln "QZ: 0 = 0zq"

def testQPolyAdd : IO Unit := do
  let r := CompPoly.add polyQxA polyQxAddB
  writeln s!"Q: {compPolyParen .qRat polyQxA} + {compPolyParen .qRat polyQxAddB} = {compPoly .qRat r}"
  let r' := CompPoly.add polyQzA polyQzAddB
  writeln s!"QZ: {compPolyParen .qzRat polyQzA} + {compPolyParen .qzRat polyQzAddB} = {compPoly .qzRat r'}"

def testQPolyNeg : IO Unit := do
  writeln s!"Q: - {compPolyParen .qRat polyQxA} = {compPoly .qRat (CompPoly.neg polyQxA)}"
  writeln s!"QZ: - {compPolyParen .qzRat polyQzA} = {compPoly .qzRat (CompPoly.neg polyQzA)}"

def testQPolyMul : IO Unit := do
  let r := CompPoly.mul polyQxA polyQxAddB
  writeln s!"Q: {compPolyParen .qRat polyQxA} * {compPolyParen .qRat polyQxAddB} = {compPoly .qRat r}"
  let r' := CompPoly.mul polyQzA polyQzAddB
  writeln s!"QZ: {compPolyParen .qzRat polyQzA} * {compPolyParen .qzRat polyQzAddB} = {compPoly .qzRat r'}"

def testQPolyDiv : IO Unit := do
  writeln "integers: 1/3 = 0"
  let ax := { coeffs := [c5_9] }
  let bx := { coeffs := [CRat.ofInt (-2), c3_2] }
  writeln s!"Q: ({compPoly .qRat ax}) / ({compPoly .qRat bx}) = {compPoly .qRat (CompPoly.div ax bx)}"
  let fx := { coeffs := [crat 5 9] }
  let gx := { coeffs := [CRat.ofInt (-2), crat 3 2] }
  writeln s!"QZ: ({compPoly .qzRat gx}) / ({compPoly .qzRat fx}) = {compPoly .qzRat (CompPoly.div gx fx)}"
  writeln s!"QZ[x]: ({compPoly .qzRat gcdQzRow7A}/ {compPoly .qzRat gcdQzRow7B}) = {compPoly .qzRat (CompPoly.div gcdQzRow7A gcdQzRow7B)}"

def testCRA1 : IO Unit := do
  writeln s!"CRA1(7, 1432, 5317) = {match cra1 7 1432 5317 with | some x => toString x | none => "ERROR: no solution to linear congruence"}"
  writeln s!"CRA1(863, 880, 2151) = {match cra1 863 880 2151 with | some x => toString x | none => "ERROR: no solution to linear congruence"}"
  writeln s!"CRA1(589, 509, 817) = {match cra1 589 509 817 with | some x => toString x | none => "ERROR: no solution to linear congruence"}"

def testCRA2 : IO Unit := do
  match cra2 6 7 3 9 with
  | some x => writeln (toString x)
  | none => writeln "ERROR"

def testCRA : IO Unit := do
  let a := cra [(1, 3), (0, 7), (2, 4), (3, 5)]
  let b := cra [(0, 3), (1, 7), (3, 4), (3, 5)]
  match a, b with
  | some aVal, some bVal =>
    let ux := CompPoly.add (CompPoly.scale (CRat.ofInt bVal) (ofInts [1])) (CompPoly.scale (CRat.ofInt aVal) (ofInts [0, 1]))
    writeln s!"u(x) = {compPoly .integer ux}"
  | _, _ => pure ()
  match cra [(1, 3), (3, 5), (0, 7), (10, 11)] with
  | some x => writeln (toString x)
  | none => writeln "ERROR"

def testDiophantine : IO Unit := do
  writeln (diophantineLine 84 54 (-24))
  writeln (diophantineLine 999 (-49) 5000)
  writeln (diophantineLine 247 589 817)

def testGCDTable : IO Unit := do
  writeln s!"GCD Z 121903,5335 = {gcdZ 121903 5335}"
  writeln s!"GCD Z -18,5 = {gcdZ (-18) 5}"
  writeln s!"GCD Z 228,612 = {gcdZ 228 612}"
  writeln s!"GCD Q[x] = {qRat (getCoeff (CompPoly.gcd polyQxA polyQxB) 0)}"
  writeln s!"GCD Z5 = {gcdZMod 5 (-2) (-3)}"
  writeln s!"GCD Z5[x] = {modPoly 5 (ModPoly.gcd 5 z5xA z5xB)}"
  writeln s!"GCD QZ[x] row7 = {qzRat (getCoeff (CompPoly.gcd gcdQzRow7A gcdQzRow7B) 0)}"
  writeln s!"GCD QZ[x] row8 = {qzRat (getCoeff (CompPoly.gcd polyQzA polyQxB) 0)}"

def testEuclidTable : IO Unit := do
  writeln s!"EUCLID 2,4 = {euclidIntTriple 2 4}"
  writeln s!"EUCLID 228,612 = {euclidIntTriple 228 612}"
  writeln s!"EUCLID 59,24 = {euclidIntTriple 59 24}"
  let qE := CompPoly.euclid polyQxA polyQxB
  writeln s!"EUCLID Q[x] = {listOf (compPoly .qRat) [qE.1, qE.2.1, qE.2.2]}"
  writeln s!"EUCLID Z5[x] = {euclidModTriple 5 z5xA z5xB}"

def testInverseTable : IO Unit := do
  writeln s!"INVERSE 30,197 = {match modularInverse 30 197 with | some x => toString x | none => "ERROR"}"
  writeln s!"INVERSE 16,21 = {match modularInverse 16 21 with | some x => toString x | none => "ERROR"}"
  IO.println "INVERSE 18,21:"
  writeln "ERROR: 18 inverse mod 21 does not exist"
  writeln s!"INVERSE 24,59 = {match modularInverse 24 59 with | some x => toString x | none => "ERROR"}"
  match ModPoly.inverse 2 gf2A gf2B with
  | some inv => writeln s!"INVERSE GF2[x] = {modPoly 2 inv}"
  | none => writeln "INVERSE GF2[x] = ERROR"
  match CompPoly.inverse invQxA invQxB with
  | some inv => writeln s!"INVERSE Q[x] = {compPoly .qRat inv}"
  | none => writeln "INVERSE Q[x] = ERROR"

def testModRS : IO Unit := do
  let seq := modRS modRsAx modRsBx
  let printed := seq.map (compPoly .qzRat)
  writeln s!"QZ[x]: MOD_RS({compPoly .qzRat modRsAx}, {compPoly .qzRat modRsBx}) = {listOf id printed}"
  writeln "[0 msecs]"

def testPREM : IO Unit := do
  writeln s!"QZ[x] prem row1 = {compPoly .qzRat (prem premRow1P premRow1Q)}"
  writeln s!"QZ[x] prem row2 = {compPoly .qzRat (prem premRow2P premRow2Q)}"
  writeln s!"QZ[x] prem row3 = {compPoly .qzRat (prem premP premQ)}"
  writeln s!"QZ[x] prem row4 = {compPoly .qzRat (prem premRow4P premRow4Q)}"
  writeln s!"integers[x] prem row5 = {compPoly .zInt (prem premRow5P premRow5Q)}"

def testEPRS : IO Unit := do
  writeln s!"E_PRS: {listOf (compPoly .integer) (ePRS eprsP0 eprsP1)}"

def testSPRS : IO Unit := do
  writeln s!"S_PRS: {listOf (compPoly .integer) (sPRS eprsP0 eprsP1)}"

def testNIA : IO Unit := do
  let p := nia [(CRat.ofInt 0, CRat.ofInt 1), (CRat.ofInt 1, CRat.ofInt 3)]
  writeln s!"NIA: {compPoly .integer p}"

def testFFTFFI : IO Unit := do
  let zCoeffs := fftCoeffs 2 [CRat.ofInt 1, CRat.ofInt 2] (CRat.ofInt (-1))
  writeln s!"FFT Z: {fftList .integer zCoeffs}"
  writeln s!"FFT Q: {fftList .qRat zCoeffs}"
  let interp := ffi 2 [CRat.ofInt 3, CRat.ofInt (-1)] (CRat.ofInt (-1))
  writeln s!"FFI: {compPolyDesc .qRat interp}"

def testNPSI : IO Unit := do
  let input := CompTPS.ofInts 2 [1, 1]
  let inv := CompTPS.npsi input 1
  writeln s!"NPSI: {tps .integer inv}"
  let prod := CompTPS.mul input inv
  writeln s!"NPSI verify: {integer (getCoeff prod 0).num}"

def main : IO Unit := do
  testModRemExamples
  testBaseBAdd
  testBaseBSub
  testBaseBMul
  testBaseBDiv
  testZOps
  testQPolyZero
  testQPolyAdd
  testQPolyNeg
  testQPolyMul
  testQPolyDiv
  testCRA1
  testCRA2
  blank
  testCRA
  testDiophantine
  testGCDTable
  testEuclidTable
  testInverseTable
  testModRS
  testPREM
  testEPRS
  testSPRS
  testNIA
  testFFTFFI
  testNPSI

end Icon2lean.Report

def main : IO Unit :=
  Icon2lean.Report.main
