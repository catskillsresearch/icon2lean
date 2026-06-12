/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Icon2lean.Domains
import Icon2lean.Euclidean
import Icon2lean.ComputablePoly
import Icon2lean.ComputableTPS

/-!
# Computability architecture

Mathlib owns mathematical truth on **noncomputable** types (`Polynomial ℚ`, `TruncPowerSeries`,
`EuclideanDomain.gcd`). Tests and `#eval` use **computable mirrors** only where the kernel cannot
reduce the canonical definitions.

## Discipline

1. **Theorems and generic algorithms** — `EuclideanDomain`, `Icon2lean.gcd`, `Icon2lean.euclid`,
   `Polynomial.lean`, `PowerSeries.lean`.
2. **`ℤ` / `ZMod p`** — `native_decide` / `decide` directly; no mirror.
3. **`Polynomial ℚ` / truncated series** — `CompPoly` / `CompTPS` for evaluation; single boundary
   maps `toMathlib` / `toRat`; coherence lemmas are the only place the two worlds meet.

## Decision matrix

| Domain | Proof layer | Test / eval layer | Bridge |
|--------|-------------|-------------------|--------|
| `ℤ` GCD / EUCLID | `EuclideanDomain ℤ` | `native_decide` on `euclid` / `euclidInt` | none |
| `ZMod p` | `EuclideanDomain (ZMod p)` | `decide` | none |
| `ℚ[x]` | `EuclideanDomain (Polynomial ℚ)` | `CompPoly` | `CompPoly.toMathlib` |
| `T(ℚ[[x]])ₙ` | `TruncPowerSeries ℚ n` | `CompTPS` | `CompTPS.toMathlib` |
-/

namespace Icon2lean.Computability

-- This module is documentation plus imports; no extra definitions.

end Icon2lean.Computability
