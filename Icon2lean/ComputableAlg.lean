/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Icon2lean.ComputablePoly
import Icon2lean.ComputableTPS

/-!
Computable mirrors of §3 algorithms for `native_decide` / `#eval`.
Proof-layer counterparts live in `Euclidean.lean`, `Polynomial.lean`, `Fft.lean`, etc.
-/

namespace Icon2lean

open CompPoly CRat CompTPS

namespace CompPoly

partial def div (p q : CompPoly) : CompPoly :=
  let rec loop (fuel : Nat) (r acc : CompPoly) : CompPoly :=
    if fuel = 0 || q.isZero || degree r < degree q then acc.trim
    else
      let dq := degree q
      let dr := degree r
      let lcR := getCoeff r dr
      let lcQ := getCoeff q dq
      if lcQ = CRat.zero then acc.trim
      else
        let k := dr - dq
        let factor := CRat.div lcR lcQ
        let term := scale factor { coeffs := (List.replicate k CRat.zero) ++ q.coeffs }
        loop (fuel - 1) (sub r term) (add acc term)
  loop (degree p + degree q + 10) (trim p) (ofInts [])

/-- Extended gcd `(g, s, t)` with `g = s * a + t * b` (report `EUCLID` on polynomials). -/
partial def euclid (a b : CompPoly) : CompPoly × CompPoly × CompPoly :=
  let rec go (fuel : Nat) (r s t r' s' t' : CompPoly) : CompPoly × CompPoly × CompPoly :=
    if fuel = 0 then (r'.trim, s'.trim, t'.trim)
    else if r.isZero then (r'.trim, s'.trim, t'.trim)
    else
      let q := div r' r
      go (fuel - 1) (mod r' r) (sub s' (mul q s)) (sub t' (mul q t)) r s t
  go (degree a + degree b + 20) a (ofInts [1]) (ofInts []) b (ofInts []) (ofInts [1])

/-- Polynomial inverse when `gcd(a, b)` is a unit (report `INVERSE` on `ℚ[x]` / `GF(2)[x]`). -/
def inverse (a b : CompPoly) : Option CompPoly :=
  let (g, _, t) := euclid b a
  let g0 := getCoeff g.trim 0
  if g.trim.coeffs.length = 1 && g0 ≠ CRat.zero then
    some (scale (CRat.div CRat.one g0) (mod b t.trim))
  else none

def ePRS (a b : CompPoly) : List CompPoly :=
  let rec go (fuel : Nat) (a b : CompPoly) : List CompPoly :=
    if fuel = 0 then [b]
    else if b.isZero then [b]
    else
      let r := prem a b
      if r.isZero then [a, b, r]
      else a :: go (fuel - 1) b r
  go (degree a + degree b + 10) a b

private def subDelta (p q : CompPoly) : Nat :=
  if degree p ≥ degree q then degree p - degree q else 0

private def subBeta (p q : CompPoly) : CRat :=
  CRat.pow (CRat.neg (getCoeff p (degree p))) (subDelta p q + 1)

private def subReduce (p q : CompPoly) : CompPoly :=
  let r := prem p q
  let β := subBeta p q
  if β = CRat.zero then r else div r (scale β (ofInts [1]))

def sPRS (a b : CompPoly) : List CompPoly :=
  if b.isZero then [a] else
    let p2 := subReduce a b
    if p2.isZero then [a, b] else
      let rec go (fuel : Nat) (prev curr : CompPoly) (acc : List CompPoly) : List CompPoly :=
        if fuel = 0 then acc.reverse
        else if curr.isZero then acc.reverse
        else
          let next := subReduce prev curr
          if next.isZero then (curr :: acc).reverse
          else go (fuel - 1) curr next (curr :: acc)
      go (degree a + degree b + 10) b p2 [a, b]

def evalAt (p : CompPoly) (x : CRat) : CRat :=
  (List.range p.coeffs.length).foldl (fun acc i =>
    CRat.add acc (CRat.mul (getCoeff p i) (CRat.pow x i))) CRat.zero

/-- Newton interpolation (report §3.3.1 `NIA`). -/
def nia (points : List (CRat × CRat)) : CompPoly :=
  match points with
  | [] => ofInts []
  | (a₀, b₀) :: rest =>
    let one := ofInts [1]
    let x := ofInts [0, 1]
    let rec loop (pts : List (CRat × CRat)) (u m : CompPoly) : CompPoly :=
      match pts with
      | [] => u
      | (a, b) :: xs =>
        let mev := evalAt m a
        if mev = CRat.zero then u
        else
          let c := CRat.div (CRat.sub b (evalAt u a)) mev
          let u' := add u (scale c m)
          let xma := sub x (scale a one)
          loop xs u' (mul m xma)
    loop rest (scale b₀ one) (sub x (scale a₀ one))

private def getL (L : List CRat) (i : Nat) : CRat := L.getD i CRat.zero

private def evenCoeffs (cs : List CRat) : List CRat :=
  (List.range (cs.length / 2 + 1)).map fun i => cs.getD (2 * i) CRat.zero

private def oddCoeffs (cs : List CRat) : List CRat :=
  (List.range ((cs.length + 1) / 2)).map fun i => cs.getD (2 * i + 1) CRat.zero

/-- Cooley–Tukey FFT on coefficient list (report §3.3.2 `FFT`). -/
def fftCoeffs (n : Nat) (cs : List CRat) (omega : CRat) : List CRat :=
  if n ≤ 1 then [cs.getD 0 CRat.zero]
  else
    let n2 := n / 2
    let B := fftCoeffs n2 (evenCoeffs cs) (CRat.mul omega omega)
    let C := fftCoeffs n2 (oddCoeffs cs) (CRat.mul omega omega)
    (List.range n2).flatMap fun k =>
      let wk := CRat.pow omega k
      let bk := getL B k
      let ck := getL C k
      [CRat.add bk (CRat.mul wk ck), CRat.sub bk (CRat.mul wk ck)]

/-- Fast Fourier interpolation (report §3.3.2 `FFI`). -/
def ffi (n : Nat) (samples : List CRat) (omega : CRat) : CompPoly :=
  let invRoot := CRat.inv omega
  let Cvals := fftCoeffs n samples invRoot
  { coeffs := Cvals.map fun c => CRat.div c (CRat.ofInt (n : Int)) }

end CompPoly

/-! ## `ℤ/pℤ[x]` (computable, for §3.1 GCD/EUCLID tables) -/

namespace ModPoly

def normalizeCoeff (p : Nat) (c : Int) : Nat :=
  let r := c % (p : Int)
  Int.toNat (if r < 0 then r + (p : Int) else r)

private def getC (cs : List Nat) (i : Nat) : Nat := cs.getD i 0

private def degree (cs : List Nat) : Nat := cs.length - 1

def trim (p : Nat) (cs : List Nat) : List Nat :=
  let rec drop (fuel : Nat) (xs : List Nat) : List Nat :=
    if fuel = 0 then xs
    else match xs.getLast? with
      | none => [0]
      | some 0 => if xs.length > 1 then drop (fuel - 1) xs.dropLast else [0]
      | _ => xs
  drop cs.length cs

def ofInts (p : Nat) (cs : List Int) : List Nat :=
  trim p (cs.map (normalizeCoeff p))

def add (p : Nat) (a b : List Nat) : List Nat :=
  let n := max a.length b.length
  trim p ((List.range n).map fun i => (getC a i + getC b i) % p)

def sub (p : Nat) (a b : List Nat) : List Nat :=
  let n := max a.length b.length
  trim p ((List.range n).map fun i => (getC a i + p - getC b i) % p)

def scale (p : Nat) (c : Nat) (cs : List Nat) : List Nat :=
  trim p (cs.map fun x => (c * x) % p)

def mul (p : Nat) (a b : List Nat) : List Nat :=
  let da := degree a
  let db := degree b
  let rec coeffAt (k : Nat) : Nat :=
    (List.range (k + 1)).foldl (fun acc i =>
      if i > da || k - i > db then acc else (acc + getC a i * getC b (k - i)) % p) 0
  trim p ((List.range (da + db + 1)).map coeffAt)

private def invMod (p : Nat) (a : Nat) : Nat :=
  let rec eg (fuel : Nat) (old_r r : Int) (old_s s : Int) : Int :=
    if fuel = 0 then 1
    else if r = 0 then old_s
    else eg (fuel - 1) r (old_r % r) s (old_s - (old_r / r) * s)
  let s := eg (p + 1) (p : Int) (a % p : Int) 0 1
  Int.toNat ((s % (p : Int) + (p : Int)) % (p : Int))

def mod (p : Nat) (a b : List Nat) : List Nat :=
  let rec loop (fuel : Nat) (r : List Nat) : List Nat :=
    if fuel = 0 then trim p r
    else if trim p b = [0] || trim p r = [0] then trim p r
    else if degree r < degree b then trim p r
    else
      let dr := degree r
      let db := degree b
      let lcR := getC r dr
      let lcB := getC b db
      if lcB = 0 then trim p r
      else
        let k := dr - db
        let factor := (lcR * invMod p lcB) % p
        let shifted := (List.replicate k 0) ++ b
        loop (fuel - 1) (sub p r (scale p factor shifted))
  loop (degree a + degree b + 10) a

partial def div (p : Nat) (a b : List Nat) : List Nat :=
  let rec loop (fuel : Nat) (r acc : List Nat) : List Nat :=
    if fuel = 0 || trim p b = [0] || degree r < degree b then trim p acc
    else
      let dr := degree r
      let db := degree b
      let lcR := getC r dr
      let lcB := getC b db
      if lcB = 0 then trim p acc
      else
        let k := dr - db
        let factor := (lcR * invMod p lcB) % p
        let term := scale p factor ((List.replicate k 0) ++ b)
        loop (fuel - 1) (sub p r term) (add p acc ((List.replicate k 0) ++ [factor]))
  loop (degree a + degree b + 10) (trim p a) [0]

def gcd (p : Nat) (a b : List Nat) : List Nat :=
  let a' := trim p a
  let b' := trim p b
  if degree a' = 0 && degree b' = 0 then
    let g := Nat.gcd (getC a' 0) (getC b' 0)
    if g = 0 then [0] else [g % p]
  else
    let rec loop (fuel : Nat) (a b : List Nat) : List Nat :=
      if fuel = 0 then trim p a
      else if trim p b = [0] then trim p a
      else loop (fuel - 1) b (mod p a b)
    loop (degree a' + degree b' + 10) a' b'

partial def euclid (p : Nat) (a b : List Nat) : List Nat × List Nat × List Nat :=
  let one := [1]
  let zero := [0]
  let rec go (fuel : Nat) (r s t r' s' t' : List Nat) : List Nat × List Nat × List Nat :=
    if fuel = 0 then (trim p r', trim p s', trim p t')
    else if trim p r = [0] then (trim p r', trim p s', trim p t')
    else
      let q := div p r' r
      go (fuel - 1) (mod p r' r)
        (sub p s' (mul p q s)) (sub p t' (mul p q t)) r s t
  go (degree a + degree b + 20) (trim p a) one zero (trim p b) zero one

def inverse (p : Nat) (a b : List Nat) : Option (List Nat) :=
  let (g, _, t) := euclid p b a
  if g = [1] then some t else none

end ModPoly

end Icon2lean
