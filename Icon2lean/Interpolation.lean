import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Algebra.Polynomial.Eval.Defs

namespace Icon2lean

open Polynomial

/-- Newton interpolation (report §3.3.1 `NIA`). -/
noncomputable def newtonInterpolation [Field R] [DecidableEq R] (points : List (R × R)) : Polynomial R :=
  match points with
  | [] => 0
  | (a₀, b₀) :: rest =>
    let rec loop (pts : List (R × R)) (u m : Polynomial R) : Polynomial R :=
      match pts with
      | [] => u
      | (a, b) :: xs =>
        let c := (b - u.eval a) / m.eval a
        let u' := u + C c * m
        let m' := m * (X - C a)
        loop xs u' m'
    loop rest (C b₀) (X - C a₀)

end Icon2lean
