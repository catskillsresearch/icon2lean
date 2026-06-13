/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

/-!
`base_B` for Icon report parity (digit vectors in variable base).
-/

namespace Icon2lean

structure BaseB where
  base : Nat
  digits : List Nat
deriving Repr

namespace BaseB

def width (base : Nat) : Nat :=
  max 1 (toString base).length - 1

def normalizeDigits (d : List Nat) : List Nat :=
  let rec drop (xs : List Nat) : List Nat :=
    match xs with
    | [] => [0]
    | [_] => xs
    | h :: t => if h = 0 then drop t else xs
  drop d

def toNat (b : BaseB) : Nat :=
  b.digits.foldl (fun acc d => acc * b.base + d) 0

def ofDigits (base : Nat) (digits : List Nat) : BaseB :=
  { base := base, digits := normalizeDigits digits }

partial def ofNat (base n : Nat) : BaseB :=
  if n = 0 then { base := base, digits := [0] }
  else
    let rec go (fuel n : Nat) (acc : List Nat) : List Nat :=
      if fuel = 0 || n = 0 then normalizeDigits (acc.reverse)
      else go (fuel - 1) (n / base) (acc ++ [n % base])
    { base := base, digits := normalizeDigits (go (n + 1) n []) }

def add (a b : BaseB) : BaseB :=
  ofNat a.base (toNat a + toNat b)

def sub (a b : BaseB) : BaseB :=
  ofNat a.base (toNat a - toNat b)

def mul (a b : BaseB) : BaseB :=
  ofNat a.base (toNat a * toNat b)

def div (a b : BaseB) : BaseB :=
  let denom := toNat b
  if denom = 0 then { base := a.base, digits := [0] } else ofNat a.base (toNat a / denom)

end BaseB

end Icon2lean
