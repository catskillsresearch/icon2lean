/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Icon2lean.Print

/-!
Executable report mirroring Icon [`tests.icn`](../../tests.icn) §3 benchmarks.

Run:

```bash
lake exe iconReport
```
-/

namespace Icon2lean.Report

open IconPrint CompPoly CRat CompTPS ModPoly

/-! ### shared test values (same as `Tests.lean`) -/

def crat (num den : Int) : CRat := CRat.normalize { num := num, den := Int.natAbs den }

def c5_9 : CRat := crat 5 9
def c16_9 : CRat := crat 16 9
def c20_9 : CRat := crat (-20) 9
def c166_243 : CRat := crat 166 243
def c275_243 : CRat := crat (-275) 243
def c115668_75625 : CRat := crat 115668 75625

def gcdQxA : CompPoly := ofInts [-2, 0, 0, 1]
def gcdQxB : CompPoly := ofInts [-3, 0, 2]
def gcdQzRow7A : CompPoly := { coeffs := [c166_243, c275_243] }
def gcdQzRow7B : CompPoly := { coeffs := [c115668_75625] }
def gcdQzRow8A : CompPoly := ofInts [-2, 0, 0, 1]
def gcdQzRow8B : CompPoly := ofInts [-3, 0, 2]

def z5xA : List Nat := ModPoly.ofInts 5 [-2, 0, 0, 1]
def z5xB : List Nat := ModPoly.ofInts 5 [-3, 0, 2]

def gf2A : List Nat := ModPoly.ofInts 2 [1, 0, 1]
def gf2B : List Nat := ModPoly.ofInts 2 [1, 0, 1, 0, 0, 1]

def invQxA : CompPoly := ofInts [-3, 0, 2]
def invQxB : CompPoly := ofInts [-2, 0, 0, 1]

def modRsAx : CompPoly := ofInts [2, -1, 3, 0, 2, 1]
def modRsBx : CompPoly := ofInts [2, -1, 0, 3]

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

/-! ### IO helpers -/

private def writeln (s : String) : IO Unit :=
  IO.println s

private def write (s : String) : IO Unit :=
  IO.print s

/-! ### benchmark sections -/

def testZOps : IO Unit := do
  writeln s!"{zInt 1} + {zInt (-999)} = {zInt ((1 : ℤ) + (-999))}"
  writeln s!"-{zInt 212} = {zInt (-(212 : ℤ))}"
  writeln s!"-{zInt (-99)} = {zInt (-(-99 : ℤ))}"
  writeln s!"{zInt 10} / {zInt 1} = {zInt ((10 : ℤ) / 1)}"
  writeln s!"{zInt 121903} / {zInt 5335} = {zInt ((121903 : ℤ) / 5335)}"
  writeln s!"{zInt 115668} / {zInt 75625} = {zInt ((115668 : ℤ) / 75625)}"
  writeln s!"{zInt 121903} mod {zInt 5335} = {zInt ((121903 : ℤ) % 5335)}"

def testCRA1 : IO Unit := do
  writeln s!"CRA1(7, 1432, 5317) = {match cra1 7 1432 5317 with | some x => toString x | none => "ERROR: no solution to linear congruence"}"
  writeln s!"CRA1(863, 880, 2151) = {match cra1 863 880 2151 with | some x => toString x | none => "ERROR: no solution to linear congruence"}"
  writeln s!"CRA1(589, 509, 817) = {match cra1 589 509 817 with | some x => toString x | none => "ERROR: no solution to linear congruence"}"

def testCRA2 : IO Unit := do
  match cra2 6 7 3 9 with
  | some x => writeln (toString x)
  | none => writeln "ERROR"

def testCRA : IO Unit := do
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
  writeln s!"GCD Q[x] = {qRat (getCoeff (CompPoly.gcd gcdQxA gcdQxB) 0)}"
  writeln s!"GCD Z5 = {gcdZMod 5 (-2) (-3)}"
  writeln s!"GCD Z5[x] = {modPoly 5 (ModPoly.gcd 5 z5xA z5xB)}"
  writeln s!"GCD QZ[x] row7 = {qzRat (getCoeff (CompPoly.gcd gcdQzRow7A gcdQzRow7B) 0)}"
  writeln s!"GCD QZ[x] row8 = {qzRat (getCoeff (CompPoly.gcd gcdQzRow8A gcdQzRow8B) 0)}"

def testEuclidTable : IO Unit := do
  writeln s!"EUCLID 2,4 = {euclidIntTriple 2 4}"
  writeln s!"EUCLID 228,612 = {euclidIntTriple 228 612}"
  writeln s!"EUCLID 59,24 = {euclidIntTriple 59 24}"
  let qE := CompPoly.euclid gcdQxA gcdQxB
  writeln s!"EUCLID Q[x] = {listOf (compPoly .qRat) [qE.1, qE.2.1, qE.2.2]}"
  writeln s!"EUCLID Z5[x] = {euclidModTriple 5 z5xA z5xB}"

def testInverseTable : IO Unit := do
  writeln s!"INVERSE 30,197 = {match modularInverse 30 197 with | some x => toString x | none => "ERROR"}"
  writeln s!"INVERSE 16,21 = {match modularInverse 16 21 with | some x => toString x | none => "ERROR"}"
  write "INVERSE 18,21: "
  match modularInverse 18 21 with
  | some x => writeln (toString x)
  | none => writeln ""
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

def testPREM : IO Unit := do
  writeln s!"QZ[x] prem row2 = {compPoly .qzRat (prem premRow2P premRow2Q)}"
  writeln s!"QZ[x] prem row3 = {compPoly .qzRat (prem premP premQ)}"
  writeln s!"QZ[x] prem row4 = {compPoly .qzRat (prem premRow4P premRow4Q)}"
  writeln s!"integers[x] prem row5 = {compPoly .zInt (prem premRow5P premRow5Q)}"

def testEPRS : IO Unit := do
  let seq := ePRS eprsP0 eprsP1
  writeln s!"E_PRS: {listOf (compPoly .integer) seq}"

def testSPRS : IO Unit := do
  let seq := sPRS eprsP0 eprsP1
  writeln s!"S_PRS: {listOf (compPoly .integer) seq}"

def testNIA : IO Unit := do
  let p := nia [(CRat.ofInt 0, CRat.ofInt 1), (CRat.ofInt 1, CRat.ofInt 3)]
  writeln s!"NIA: {compPoly .integer p}"

def testFFTFFI : IO Unit := do
  let zCoeffs := fftCoeffs 2 [CRat.ofInt 1, CRat.ofInt 2] (CRat.ofInt (-1))
  writeln s!"FFT Z: {fftList .integer zCoeffs}"
  let qCoeffs := fftCoeffs 2 [CRat.ofInt 1, CRat.ofInt 2] (CRat.ofInt (-1))
  writeln s!"FFT Q: {fftList .qRat qCoeffs}"
  let interp := ffi 2 [CRat.ofInt 3, CRat.ofInt (-1)] (CRat.ofInt (-1))
  writeln s!"FFI: {compPoly .qRat interp}"

def testNPSI : IO Unit := do
  let input := CompTPS.ofInts 2 [1, 1]
  let inv := CompTPS.npsi input 1
  writeln s!"NPSI: {tps .integer inv}"
  let prod := CompTPS.mul input inv
  writeln s!"NPSI verify: {integer (getCoeff prod 0).num}"

def main : IO Unit := do
  testZOps
  testCRA1
  testCRA2
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
