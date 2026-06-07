/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Mathlib.Data.Int.GCD

/-!
Computable dense polynomials over normalized rationals, for `native_decide`
checks of the report §3.2 examples. Mirrors `PREM` and `MOD_RS` from
`Icon2lean/Polynomial.lean` on a computable representation.
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

def mod (p q : CompPoly) : CompPoly :=
  let rec loop (fuel : Nat) (r : CompPoly) : CompPoly :=
    if fuel = 0 then r.trim
    else if isZero q || isZero r || degree r < degree q then r.trim
    else
      let dq := degree q
      let dr := degree r
      let lcQ := getCoeff q dq
      if lcQ = CRat.zero then r.trim
      else
        let k := dr - dq
        let lcR := getCoeff r dr
        let factor := CRat.div lcR lcQ
        let shifted := { coeffs := (List.replicate k CRat.zero) ++ q.coeffs }
        loop (fuel - 1) (sub r (scale factor shifted))
  loop (degree p + degree q + 2) (trim p)

def prem (p q : CompPoly) : CompPoly :=
  if isZero q then p
  else
    let d := if degree p ≥ degree q then degree p - degree q else 0
    let b := getCoeff q (degree q)
    mod (scale (CRat.pow b (d + 1)) p) q

def modRS (a b : CompPoly) : List CompPoly :=
  let rec go (fuel : Nat) (a b : CompPoly) : List CompPoly :=
    if fuel = 0 then [a]
    else if isZero b then [a, b]
    else a :: go (fuel - 1) b (mod a b)
  go (degree a + degree b + 10) a b

end CompPoly

end Icon2lean
