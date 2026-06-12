/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Data.Rat.Defs
import Mathlib.Data.Int.GCD

/-!
Computable dense polynomials over `ℚ` for `native_decide` / `#eval`.

Canonical (proof) type: `Polynomial ℚ` with `EuclideanDomain` / operations in `Polynomial.lean`.
Coherence: `CompPoly.toMathlib` is the sole boundary map; prove ring-homomorphism lemmas there only.
-/

namespace Icon2lean

/-- Normalized rational: `num / den` with `den > 0`, reduced unless `num = 0`. -/
structure CRat where
  num : Int
  den : Nat
deriving DecidableEq, Repr

namespace CRat

def zero : CRat := { num := 0, den := 1 }
def one : CRat := { num := 1, den := 1 }

def ofInt (z : Int) : CRat :=
  if z = 0 then zero else { num := z, den := 1 }

def normalize (r : CRat) : CRat :=
  if r.num = 0 then zero
  else
    let g := Nat.gcd (Int.natAbs r.num) (max 1 r.den)
    { num := r.num / (g : Int), den := max 1 (r.den / g) }

def add (x y : CRat) : CRat :=
  normalize { num := x.num * (y.den : Int) + y.num * (x.den : Int), den := x.den * y.den }

def neg (x : CRat) : CRat := { x with num := -x.num }

def sub (x y : CRat) : CRat := add x (neg y)

def mul (x y : CRat) : CRat :=
  normalize { num := x.num * y.num, den := x.den * y.den }

def inv (x : CRat) : CRat :=
  if x.num = 0 then zero
  else if x.num ≥ 0 then normalize { num := x.den, den := Int.natAbs x.num }
  else normalize { num := -x.den, den := Int.natAbs x.num }

def div (x y : CRat) : CRat := mul x (inv y)

def pow (x : CRat) (n : Nat) : CRat :=
  match n with
  | 0 => one
  | n + 1 => mul x (pow x n)

/-- Computable embedding into Mathlib `ℚ`. -/
def toRat (r : CRat) : ℚ :=
  (r.num : ℚ) / r.den

end CRat

/-- Dense polynomial: `coeffs[i]` is the coefficient of `X^i`. -/
structure CompPoly where
  coeffs : List CRat
deriving DecidableEq, Repr, Inhabited

namespace CompPoly

def ofInts (cs : List Int) : CompPoly :=
  { coeffs := cs.map CRat.ofInt }

def trim (p : CompPoly) : CompPoly :=
  let rec dropTrailing (fuel : Nat) (cs : List CRat) : List CRat :=
    if fuel = 0 then cs
    else
      match cs.getLast? with
      | none => [CRat.zero]
      | some a =>
        if a = CRat.zero && cs.length > 1 then
          dropTrailing (fuel - 1) cs.dropLast
        else
          cs
  { coeffs := dropTrailing p.coeffs.length p.coeffs }

def degree (p : CompPoly) : Nat :=
  p.coeffs.length - 1

def getCoeff (p : CompPoly) (i : Nat) : CRat :=
  p.coeffs.getD i CRat.zero

def isZero (p : CompPoly) : Bool :=
  p.trim = { coeffs := [CRat.zero] }

def add (p q : CompPoly) : CompPoly :=
  let n := max p.coeffs.length q.coeffs.length
  let rec build (fuel i : Nat) (acc : List CRat) : List CRat :=
    if fuel = 0 then acc.reverse
    else build (fuel - 1) (i + 1) (CRat.add (getCoeff p i) (getCoeff q i) :: acc)
  trim { coeffs := build n 0 [] }

def neg (p : CompPoly) : CompPoly :=
  { coeffs := p.coeffs.map CRat.neg }

def sub (p q : CompPoly) : CompPoly := add p (neg q)

def scale (c : CRat) (p : CompPoly) : CompPoly :=
  { coeffs := p.coeffs.map (CRat.mul c ·) }

def mul (p q : CompPoly) : CompPoly :=
  let n := degree p + degree q
  let rec coeffAt (k : Nat) : CRat :=
    (List.range (k + 1)).foldl (fun acc i =>
      if i > degree p || k - i > degree q then acc
      else CRat.add acc (CRat.mul (getCoeff p i) (getCoeff q (k - i)))) CRat.zero
  let rec build (fuel k : Nat) (acc : List CRat) : List CRat :=
    if fuel = 0 then acc.reverse
    else build (fuel - 1) (k + 1) (coeffAt k :: acc)
  trim { coeffs := build (n + 1) 0 [] }

/-- Icon `div_poly`: quotient of `a` by `b`; when both are constants (`m = n = 0`), one step and return. -/
partial def div (a b : CompPoly) : CompPoly :=
  if isZero b then ofInts []
  else if isZero (trim a) then ofInts [0]
  else
    let fuel := degree a + degree b + 20
    let rec loop (fuel : Nat) (r acc : CompPoly) : CompPoly :=
      if fuel = 0 || isZero r then acc.trim
      else
        let n := degree b
        let m := degree r
        if m < n then acc.trim
        else
          let lcR := getCoeff r m
          let lcQ := getCoeff b n
          if lcQ = CRat.zero then acc.trim
          else
            let k := m - n
            let factor := CRat.div lcR lcQ
            let qterm := { coeffs := (List.replicate k CRat.zero) ++ [factor] }
            let subtrahend := mul qterm b
            if m = 0 then (add acc qterm).trim
            else loop (fuel - 1) (sub r subtrahend) (add acc qterm)
    loop fuel (trim a) (ofInts [])

/-- Icon `mod_poly`: `a - b * div(a, b)`. -/
def mod (p q : CompPoly) : CompPoly :=
  (sub (trim p) (mul q (div p q))).trim

def prem (p q : CompPoly) : CompPoly :=
  if isZero q then p
  else
    let d := if degree p ≥ degree q then degree p - degree q else 0
    let b := getCoeff q (degree q)
    mod (scale (CRat.pow b (d + 1)) p) q

partial def modRS (a b : CompPoly) : List CompPoly :=
  let rec go (a b : CompPoly) : List CompPoly :=
    if isZero b then [a, b]
    else a :: go b (mod a b)
  go a b

/-- Euclidean gcd in the computable layer (report §3.1.1 on `ℚ[x]`). -/
def gcd (p q : CompPoly) : CompPoly :=
  let rec loop (fuel : Nat) (a b : CompPoly) : CompPoly :=
    if fuel = 0 then a.trim
    else if isZero b then a.trim
    else loop (fuel - 1) b (mod a b)
  loop (degree p + degree q + 10) (trim p) (trim q)

/-- Boundary map into canonical `Polynomial ℚ`. -/
noncomputable def toMathlib (p : CompPoly) : Polynomial ℚ :=
  (List.range p.coeffs.length).foldl (fun acc i =>
    acc + Polynomial.C (CRat.toRat (p.coeffs.getD i CRat.zero)) * Polynomial.X ^ i) 0

/-!
### Coherence targets (to prove)

* `toMathlib (add p q) = toMathlib p + toMathlib q` (and likewise for `mul`, `mod`, `gcd`)
* `EuclideanDomain.gcd (toMathlib p) (toMathlib q) = toMathlib (gcd p q)`
-/

end CompPoly

end Icon2lean
