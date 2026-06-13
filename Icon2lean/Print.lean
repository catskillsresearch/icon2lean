/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Icon2lean.BaseB
import Icon2lean.ComputableAlg
import Icon2lean.ComputableTPS
import Icon2lean.Diophantine
import Icon2lean.Euclidean

/-!
Icon/report pretty-printing (1986 `print_*` family in `code.icn`).

Lean's `Repr` / `ToString` are for debugging; parity output uses these formatters so
`lake exe iconReport` can be diffed against Icon `tests.icn` stdout.
-/

namespace Icon2lean

open CompPoly CRat CompTPS ModPoly

namespace IconPrint

/-! ### scalars -/

/-- `print_integer`: negative values in parentheses. -/
def integer (n : Int) : String :=
  if n < 0 then s!"({n})" else toString n

/-- `print_Z`: mantissa with `z` suffix; negative wrapped in parens. -/
def zInt (n : Int) : String :=
  if n < 0 then s!"({n}z)" else s!"{n}z"

/-- `print_Q` on normalized `CRat`. -/
def qRat (r : CRat) : String :=
  let r := CRat.normalize r
  if r.num = 0 then "0q"
  else if r.den = 1 then
    if r.num < 0 then s!"({r.num})q" else s!"{r.num}q"
  else if r.num < 0 then
    s!"(({r.num})/{r.den})q"
  else s!"({r.num}/{r.den})q"

/-- `print_Q` on `QZ` (rational whose dividend/divisor are Icon `Z`). -/
def qzRat (r : CRat) : String :=
  let r := CRat.normalize r
  if r.num = 0 then "0zq"
  else if r.den = 1 then
    if r.num < 0 then s!"({r.num}z)q" else s!"{r.num}zq"
  else if r.num < 0 then
    s!"(({r.num}z)/{r.den}z)q"
  else
    s!"({r.num}z/{r.den}z)q"

/-- `print_modulo`: `(item mod modulus)`. -/
def modInt (item modulus : Int) : String :=
  s!"({item} mod {modulus})"

def modNat (p : Nat) (c : Nat) : String :=
  s!"({c} mod {p})"

/-! ### lists (Icon `print` on lists) -/

def listOf {α : Type} (printElem : α → String) (xs : List α) : String :=
  match xs with
  | [] => "[]"
  | ys => s!"[{String.intercalate ", " (ys.map printElem)}]"

/-! ### polynomials -/

inductive CoefStyle
  | integer
  | zInt
  | qRat
  | qzRat
  deriving DecidableEq

def printCoef (style : CoefStyle) (c : CRat) : String :=
  match style with
  | .integer => integer c.num
  | .zInt => zInt c.num
  | .qRat => qRat c
  | .qzRat => qzRat c

private def nonZeroTerms (p : CompPoly) : List (Nat × CRat) :=
  let p := p.trim
  (List.range p.coeffs.length).filterMap fun i =>
    let c := p.coeffs.getD i CRat.zero
    if c = CRat.zero then none else some (i, c)

private def printTerm (style : CoefStyle) (power : Nat) (c : CRat) : String :=
  let cs := printCoef style c
  if power = 0 then cs
  else if power = 1 then cs ++ "*X"
  else cs ++ s!"*X^{power}"

def compPoly (style : CoefStyle) (p : CompPoly) : String :=
  match nonZeroTerms p with
  | [] =>
    match style with
    | .integer => "0"
    | .zInt => "0z"
    | .qRat => "0q"
    | .qzRat => "0zq"
  | (i, c) :: rest =>
    let head := printTerm style i c
    rest.foldl (fun acc (j, d) => acc ++ "+ " ++ printTerm style j d) head

/-- Wrap multi-term polynomials in parentheses (Icon `pr` on operands). -/
def compPolyParen (style : CoefStyle) (p : CompPoly) : String :=
  let s := compPoly style p
  if s.contains "+ " then s!"({s})" else s

/-- Descending term order (Icon `FFI` output). -/
def compPolyDesc (style : CoefStyle) (p : CompPoly) : String :=
  match nonZeroTerms p with
  | [] => compPoly style p
  | terms =>
    let terms' := terms.reverse
    match terms' with
    | (i, c) :: rest =>
      let head := printTerm style i c
      rest.foldl (fun acc (j, d) => acc ++ "+ " ++ printTerm style j d) head
    | [] => compPoly style p

def intPolyRemScalar (p : CompPoly) (m : Int) : CompPoly :=
  let norm (x : Int) : Int := Int.emod x m
  { coeffs := p.coeffs.map fun r => CRat.ofInt (norm r.num) }

def remPoly (style : CoefStyle) (p q : CompPoly) : String :=
  compPoly style (CompPoly.mod p q)

private def nonZeroModTerms (p : Nat) (cs : List Nat) : List (Nat × Nat) :=
  let cs := ModPoly.trim p cs
  (List.range cs.length).filterMap fun i =>
    let c := cs.getD i 0
    if c = 0 then none else some (i, c)

private def printModTerm (p : Nat) (power : Nat) (c : Nat) : String :=
  let cs := modNat p c
  if power = 0 then cs
  else if power = 1 then cs ++ "*X"
  else cs ++ s!"*X^{power}"

def modPoly (p : Nat) (cs : List Nat) : String :=
  match nonZeroModTerms p cs with
  | [] => s!"({0} mod {p})"
  | (i, c) :: rest =>
    let head := printModTerm p i c
    rest.foldl (fun acc (j, d) => acc ++ "+ " ++ printModTerm p j d) head

/-! ### truncated power series (Icon prints `.Poly`) -/

def tps (style : CoefStyle) (t : CompTPS) : String :=
  compPoly style { coeffs := t.coeffs }

/-! ### domain helpers -/

def gcdZ (a b : Int) : String :=
  zInt (Int.gcd a b)

def gcdZMod (p : Nat) (a b : Int) : String :=
  let norm (x : Int) : Nat :=
    Int.toNat ((x % (p : Int) + (p : Int)) % (p : Int))
  modNat p (Nat.gcd (norm a) (norm b))

def euclidIntTriple (A B : Int) : String :=
  let (g, s, t) := euclidInt A B
  listOf integer [g, s, t]

def euclidModTriple (p : Nat) (a b : List Nat) : String :=
  let (g, s, t) := ModPoly.euclid p a b
  listOf (modPoly p) [g, s, t]

def signedGcd (A B : ℤ) : ℤ :=
  let g := (Int.gcd A B : ℤ)
  if g = 0 then 0 else if B < 0 then -g else g

def diophantineLine (a b c : Int) : String :=
  match diophantine a b c with
  | none => s!"DIOPHANTINE({a}, {b}, {c}) = ERROR"
  | some s =>
    s!"DIOPHANTINE({a}, {b}, {c}) = [{integer (signedGcd a b)}, {integer s.x0}, {integer s.y0}]"

def fftList (style : CoefStyle) (cs : List CRat) : String :=
  listOf (printCoef style) cs

/-! ### `base_B` (Icon `print_base_B`) -/

def baseB (b : BaseB) : String :=
  let w := BaseB.width b.base
  let fmt (d : Nat) : String :=
    let s := toString d
    if s.length ≥ w then s
    else String.mk (List.replicate (w - s.length) '0' ++ s.toList)
  match b.digits with
  | [] => s!"0 #{b.base}#"
  | h :: t =>
    s!"{fmt h}{t.foldl (fun acc d => acc ++ " " ++ fmt d) ""} #{b.base}#"

end IconPrint

end Icon2lean
