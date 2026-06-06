import Icon2lean.Gcd

namespace Icon2lean

/-- Single linear congruence `a * x ≡ b (mod m)` (report §3.1.3 `CRA1`). -/
partial def cra1 (aa bb m : Int) : Option Int :=
  let g := Int.gcd aa m
  if bb % (g : Int) ≠ 0 then
    none
  else
    let a := aa % m
    let b := bb % m
    if a = 1 then
      some b
    else if b = 0 then
      some 0
    else if a = b then
      modularInverse b m
    else
      match cra1 m (-b) a with
      | none => none
      | some y =>
        if a = 0 then none else some ((m * y + b) / a)

/-- Two-congruence Chinese remainder (report §3.1.3 `CRA2`). -/
def cra2 (r m s n : Int) : Option Int :=
  match modularInverse m n with
  | none => none
  | some inv =>
    let sigma := ((s - r) * inv) % n
    some (r + m * sigma)

/-- N-congruence Chinese remainder on pairs `(residue, modulus)` (report §3.1.3 `CRA`). -/
def cra (congs : List (Int × Int)) : Option Int :=
  match congs with
  | [] => some 0
  | (r0, m0) :: rest =>
    let rec go (U M : Int) (remaining : List (Int × Int)) : Option Int :=
      match remaining with
      | [] => some U
      | (r, m) :: rs =>
        match modularInverse M m with
        | none => none
        | some inv =>
          let t := ((r - U) * inv) % m
          go (U + M * t) (M * m) rs
    go (r0 % m0) m0 rest

end Icon2lean
