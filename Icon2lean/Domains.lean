/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Mathlib.Algebra.EuclideanDomain.Defs
import Mathlib.Algebra.EuclideanDomain.Int
import Mathlib.Algebra.Field.ZMod
import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Algebra.Polynomial.FieldDivision
import Mathlib.Data.Rat.Defs
import Mathlib.Data.ZMod.Units
import Mathlib.RingTheory.PowerSeries.Basic
import Mathlib.RingTheory.PowerSeries.Inverse
import Icon2lean.Types

/-!
# Euclidean domains and constructors (report §2)

**Phase 1 — types and instances only.**

## Hierarchy

**Euclidean domain** (modern name for the report's "quotient Euclidean domain"):

```
CommRing → IsDomain → EuclideanDomain     (ℤ, ℚ, ℤ/(p) when p prime, F[x] when F a field)
```

**Domain constructors** (this file + `Types.lean`):

| Constructor | Type | Euclidean when |
|-------------|------|----------------|
| modular `D/(e)` | `ModularDomain R I` / `ModularInt n` | `R ⧸ I` a field (e.g. `n` prime) |
| polynomial `D[x]` | `PolyDomain R` | coefficients form a field |
| truncated series `T(D[[x]])ₙ` | `TruncPowerSeries R n` | `CommRing` (not Euclidean in general) |

Formal (untruncated) power series `PowerSeries R` support `NPSI` inversion but are not
Euclidean domains.

### Report operators → Mathlib

| Report | Mathlib |
|--------|---------|
| `⊕_Q` | `+` |
| `-_Q` | `-` / negation |
| `⊗_Q` | `*` |
| `⨸_Q` | `EuclideanDomain.quotient` (`/`) |
| `mod_Q` | `EuclideanDomain.remainder` (`%`) |
| `normalize_Q` | `normalize` (`NormalizedGCDMonoid`) |
| `deg_Q` / `deg_poly` (`"-∞"` for zero) | `EuclideanDomain.r` / `Polynomial.degree : WithBot ℕ` |
| `unit_Q` / `unit_modulo` / `unit_poly` | `IsUnit` |

### Computability

`Polynomial ℚ`, `TruncPowerSeries R n`, and `PowerSeries R` are noncomputable in Mathlib.
`#eval` / `native_decide` use the separate computable layer in `ComputablePoly.lean`.
-/

namespace Icon2lean.Domains

open Polynomial

/-! ## Base Euclidean domains -/

example : EuclideanDomain ℤ := inferInstance
example : Field ℚ := inferInstance
example : EuclideanDomain ℚ := inferInstance

#check EuclideanDomain
#check EuclideanDomain.gcd
#check EuclideanDomain.xgcd
#check NormalizedGCDMonoid
#check IsUnit

#check (EuclideanDomain.gcd : ℤ → ℤ → ℤ)

/-! ## Modular domain `D/(e)` -/

/-- `ℤ/5ℤ` — §3.1 GCD/EUCLID/INVERSE tables. -/
abbrev Z5 := ModularInt 5

/-- `ℤ/2ℤ` = GF(2) — §3.1.2 `INVERSE` and GF(2)[*x*]. -/
abbrev GF2 := ModularInt 2

local instance : Fact (Nat.Prime 5) := ⟨by decide⟩
local instance : Fact (Nat.Prime 2) := ⟨by decide⟩

noncomputable example : CommRing Z5 := inferInstance
example : Field Z5 := inferInstance
example : EuclideanDomain Z5 := inferInstance

#check (ZMod 5 : Type)
#check (Ideal.Quotient.mk (Ideal.span {(5 : ℤ)}) : ℤ →+* ModularDomain ℤ (Ideal.span {(5 : ℤ)}))
#check ZMod.unitOfCoprime

#check ZMod.unitOfCoprime 2 (show Nat.Coprime 2 5 by decide)

#check ((3 : Z5) + (4 : Z5) : Z5)

/-! ## Polynomial domain `D[x]` -/

abbrev Z5Poly := PolyDomain Z5
abbrev GF2Poly := PolyDomain GF2
abbrev RatPoly := PolyDomain ℚ

noncomputable example : CommRing Z5Poly := inferInstance
noncomputable example : EuclideanDomain Z5Poly := inferInstance

noncomputable example : CommRing GF2Poly := inferInstance
noncomputable example : EuclideanDomain GF2Poly := inferInstance

noncomputable example : CommRing RatPoly := inferInstance
noncomputable example : EuclideanDomain RatPoly := inferInstance

/-- Coefficients only an integral domain (not a field): polynomial ring is not Euclidean. -/
example : IsDomain (PolyDomain ℤ) := inferInstance

#check Polynomial.degree
#check Polynomial.leadingCoeff
#check Polynomial.eval
#check Polynomial.divByMonic
#check Polynomial.map

noncomputable def poly_x3_minus_2 : RatPoly := Polynomial.X ^ 3 - Polynomial.C 2
noncomputable def z5poly_1_plus_x : Z5Poly := Polynomial.C 1 + Polynomial.X

#check (EuclideanDomain.gcd : Z5Poly → Z5Poly → Z5Poly)

/-! ## Truncated power series `T(D[[x]])ₙ` -/

noncomputable example : CommRing (TruncPowerSeries ℚ 4) := inferInstance

noncomputable def smoke_trunc_ps : TruncPowerSeries ℚ 4 :=
  truncMk 4 (Polynomial.X ^ 2 + Polynomial.C 3)

#check (truncatePoly 4 (Polynomial.X ^ 3 + Polynomial.C 1) : PolyDomain ℚ)

/-! ## Formal power series `D[[x]]` (not truncated) -/

noncomputable example : CommRing (PowerSeries ℚ) := inferInstance

#check PowerSeries.coeff
#check PowerSeries.invOfUnit

/-! ## Gaps -/

/-- `ℤ/6ℤ` is `CommRing` but not `Field` or `EuclideanDomain`; the report still runs `GCD`
on modular values when the modulus is composite. -/
noncomputable example : CommRing (ModularInt 6) := inferInstance

end Icon2lean.Domains
