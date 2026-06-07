/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Mathlib.Data.Int.GCD

namespace Icon2lean

/-- `GCD` over `Int` (report §3.1.1). -/
def gcdInt (a b : Int) : Nat :=
  Int.gcd a b

/-- Extended gcd: returns `(g, s, t)` with `g = s*A + t*B` (report §3.1.1 `EUCLID`). -/
def euclidInt (A B : Int) : Nat × Int × Int :=
  (Int.gcd A B, Int.gcdA A B, Int.gcdB A B)

theorem euclidInt_bezout (A B : Int) :
    (Int.gcd A B : Int) = A * Int.gcdA A B + B * Int.gcdB A B :=
  Int.gcd_eq_gcd_ab A B

/-- Modular inverse of `a` modulo `m`, using `EUCLID(m, a)` (report §3.1.2). -/
def modularInverse (a m : Int) : Option Int :=
  let g := Int.gcd m a
  if g = 1 then
    some (Int.emod (Int.gcdB m a / (g : Int)) m)
  else
    none

end Icon2lean
