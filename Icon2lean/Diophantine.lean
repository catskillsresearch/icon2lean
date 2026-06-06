import Icon2lean.Congruence
import Icon2lean.Gcd

namespace Icon2lean

structure DiophantineSolution where
  g : Nat
  x0 : Int
  y0 : Int

/-- Particular solution to `a * x + b * y = c` when one exists (report §3.1.4). -/
def solveDiophantine (a b c : Int) : Option DiophantineSolution :=
  let g := Int.gcd a b
  if c % (g : Int) = 0 then
    let k := c / (g : Int)
    some { g := g, x0 := Int.gcdA a b * k, y0 := Int.gcdB a b * k }
  else
    none

/-- Report-style path using `CRA1` when `|b| ≤ |a|` (equivalent to `solveDiophantine`). -/
def diophantineViaCra1 (a b c : Int) : Option DiophantineSolution :=
  let g := Int.gcd a b
  if c % (g : Int) ≠ 0 then
    none
  else if Int.natAbs b ≤ Int.natAbs a then
    match cra1 a c (Int.natAbs b) with
    | none => none
    | some x1 =>
      if b = 0 then none else
        some { g := g, x0 := x1, y0 := (c - a * x1) / b }
  else
    match cra1 b c (Int.natAbs a) with
    | none => none
    | some y1 =>
      if a = 0 then none else
        some { g := g, x0 := (c - b * y1) / a, y0 := y1 }

end Icon2lean
