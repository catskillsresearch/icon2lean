# A Lean 4 Formalization of Euclidean Domain Algorithms from a 1986 Icon Experimentation Package

**Lars Warren Ericson** (original Icon implementation, 1986)  
**Lean 4 port** (2026)

---

## Abstract

We describe a Lean 4 formalization of the algorithms and domain types from NYU Computer Science Technical Report #232, *An ICON Package for Experimenting with Euclidean Domains* (Ericson, 1986). The original system implemented Lipson's catalog of procedures over integers, rationals, modular rings, polynomial rings, and truncated power series, using a custom runtime dispatch mechanism in Icon. The present work separates mathematical definitions (grounded in Mathlib's `EuclideanDomain` hierarchy), computable mirrors suitable for evaluation and regression testing, and report-formatting infrastructure that reproduces the 1986 benchmark output byte-for-byte. All fourteen application algorithms from Section 3 of the report are implemented without axioms or `sorry`. We classify each procedure by its relation to existing Mathlib infrastructure, identify coherence obligations between proof and executable layers, and state precisely what is theorem-backed versus regression-trusted. The formalization is intended as a bridge between classical computer-algebra practice and modern interactive theorem proving.

---

## 1. Introduction

In August 1986, at New York University's Courant Institute of Mathematical Sciences, Ericson authored Technical Report #232 with the goal of responsibly implementing algorithms over mathematical structures—integers, quotient rings, polynomials, and power series—following Lipson's *Elements of Algebra and Algebraic Computing*. Icon was chosen as the implementation language because it supported symbolic computation idioms, even though it lacked native typeclasses or object-oriented dispatch. Generic division and arithmetic across distinct domains were realized via a custom runtime dispatch system using string reflection.

Thirty-nine years later, we present a Lean 4 port of the report's domain types (Section 2) and application algorithms (Sections 1.2 and 3). The port is complete in the sense that every algorithm listed in the report's application suite is defined and typechecked; no proof obligations are deferred via `sorry`. Source Icon listings and OCR'd report text are preserved alongside the executable formalization.

The central methodological question is not merely translation but *stratification*: Mathlib provides canonical, often noncomputable, mathematical objects (`Polynomial ℚ`, `TruncPowerSeries`, `EuclideanDomain.gcd`), while the 1986 package was an *experimental* system whose correctness was established by exhaustive printed tables on selected inputs. We therefore maintain three layers—proof, computable, and report—and document explicitly which claims belong to each epistemic tier.

**Notation.** Icon listings in the original report use *fancy notation* (Section 1.3): `©` denotes division, `®` addition, `—` subtraction, `F (args) <= body ■` a procedure definition, and `■` return.

---

## 2. Domain Types

The report's **quotient Euclidean domain** corresponds to Mathlib's `EuclideanDomain`. Primitive domains are ℤ and ℚ. Three constructors build composite domains:

| Constructor | Report notation | Lean type |
|-------------|-----------------|-----------|
| Modular quotient \(D/(e)\) | `modulo(item, modulus)` | `ModularDomain R I` or `ModularInt n` (= `ZMod n`) |
| Polynomial ring \(D[x]\) | `poly(terms)` | `PolyDomain R` (= `Polynomial R`) |
| Truncated series \(T(D\llbracket x\rrbracket)_n\) | `tpower(poly, N)` | `TruncPowerSeries R n` (= \(R[x]/(X^n)\)) |

Formal power series \(D\llbracket x\rrbracket\) use `PowerSeries R` (for Newton power-series inversion); they are not Euclidean domains.

### 2.1 Primitive and composite instances

- **Integers.** `Int` / notation ℤ. Instance: `EuclideanDomain ℤ`.
- **Rationals.** `Rat` / notation ℚ. `Field ℚ` induces `EuclideanDomain ℚ`.
- **Modular rings.** General quotients via `Ideal.Quotient.mk`; units via `ZMod.unitOfCoprime`. No `LinearOrder` on `ZMod n`, matching the report's `<0_modulo` predicate (always false).
- **Polynomials.** `Polynomial.degree : WithBot ℕ`, with `⊥` corresponding to the report's `"-∞"` for the zero polynomial. When \(F\) is a field, `Polynomial F` is a `EuclideanDomain`.
- **Truncated series.** `truncatePoly n p` implements multiply-then-truncate in \(R[x]/(X^n)\).

### 2.2 Variable-base digit arithmetic (`base_B`)

Section 2.2 of the report defines variable-base digit arithmetic. This is not Mathlib infrastructure. For benchmark reproduction we provide `BaseB.lean`: digit vectors, `toNat` / `ofNat`, and `add` / `sub` / `mul` / `div` via natural conversion. This layer is a **computable report helper**, not a verified arbitrary-precision base-\(B\) ring.

---

## 3. Application Algorithms

Fourteen algorithms from Section 1.2 of the report. Proof-layer definitions are generic over `EuclideanDomain` or `Polynomial R` where possible; the computable layer reimplements Icon control flow for ℚ\([x]\), ℤ/\(p\)ℤ\([x]\), and truncated series.

### 3.1 Extended gcd and modular inverse

**GCD.** Icon: recursive `GCD(b, mod(a,b))` until \(b = 0\). Lean proof layer: `euclideanGcd`, `euclid` on any `EuclideanDomain`; `euclidInt` / `euclidZ` on ℤ with `Int.gcdA` / `Int.gcdB`. Computable layer: `CompPoly.euclid`, `ModPoly.euclid` — Icon state machine with fuel guards.

**EUCLID.** Icon: extended gcd loop updating \((a, s, t)\) triples. Report example: \(\mathrm{EUCLID}(84, 54) = (6, 2, -3)\).

**INVERSE.** Icon: `gst := EUCLID(m, a)` then `mod(div(gst[3], gst[1]), m)` when `unit(gst[1])`. Lean: `modularInverse` on ℤ; `CompPoly.inverse` / `ModPoly.inverse` on polynomial domains. Argument order **`EUCLID(m, a)`** (modulus first) is part of the specification.

### 3.2 Chinese remainder and Diophantine equations

**CRA1, CRA2, CRA.** Icon: recursive `CRA1`; `CRA2` and `CRA` built from `INVERSE` and `mod`. Lean: `Congruence.lean`, using `iconMod` (`Int.emod`) for Icon's non-negative remainder convention. Report examples include scalar CRA tables and polynomial CRA yielding \(u(x) = 183 + 238x\).

**DIOPHANTINE.** Icon: `EUCLID` + `CRA1` with branch on \(|b| < |a|\). Lean: `Diophantine.lean`.

### 3.3 Polynomial remainder sequences

**MOD\_RS.** Icon: `MOD_RS(a,b) = [a] || MOD_RS(b, mod(a,b))`. Lean proof: `Polynomial.modRS`; computable: `CompPoly.modRS`. Report: six-term ℚ\([x]\) sequence ending in 0.

**PREM.** Icon: scale by \(\mathrm{lead\_coef}(q)^{\deg\_\mathrm{diff}+1}\), then `rem`. Lean: `prem` in both layers.

**E\_PRS and S\_PRS.** Icon: `E_PRS` uses `PREM`; `S_PRS` is the Collins–Brown subresultant PRS. Lean: `ePRS`, `sPRS` in both layers.

These algorithms constitute the most algebraically subtle part of the suite. Mathlib provides polynomial `%` and `EuclideanDomain.gcd` over fields but does not ship pseudo-remainder, remainder sequences with intermediate coefficient swell, Euclidean PRS with pseudo-remainders, or Collins–Brown subresultant PRS as named definitions matching Lipson's recipes.

### 3.4 Interpolation, FFT, and power-series inversion

**NIA.** Newton interpolation on point lists. Lean: `newtonInterpolation` (proof); `CompPoly.nia` (eval).

**FFT and FFI.** Icon `FFT`: Cooley–Tukey decimation on even/odd coefficient splits. Icon `FFI`: `polynomialize` → `FFT` with `inverse(omega)` → scale by \(1/N\). Lean: `evenTerms` / `oddTerms` / `fftCoeffs` / `ffi` in `Fft.lean`; computable twins on `List CRat`.

**NPSI.** Newton truncated power-series inversion. Lean: `npsi`, `npsiTrunc` (proof); `CompTPS.npsi` (eval).

---

## 4. Architecture

The 1986 package conflated three concerns: representing Euclidean domains, executing algorithms, and printing benchmark tables in a fixed Icon format. The Lean port separates them deliberately.

### 4.1 Three layers

| Layer | Role | Representative modules |
|-------|------|------------------------|
| **Proof / canonical** | Mathlib-backed types and noncomputable definitions suitable for theorems | `Types.lean`, `Domains.lean`, `Euclidean.lean`, `Polynomial.lean`, `Fft.lean`, `Congruence.lean`, … |
| **Computable / eval** | Mirrors that `#eval`, `native_decide`, and `lake exe` can reduce | `ComputablePoly.lean`, `ComputableAlg.lean`, `ComputableTPS.lean`, `BaseB.lean` |
| **Report / print** | Icon-style formatters and the full `tests.icn` benchmark driver | `Print.lean`, `Report.lean` |

**Design rationale.** Mathlib's polynomial and gcd infrastructure is the correct mathematical substrate, but it is **noncomputable**—the Lean kernel cannot evaluate it for regression tests. We therefore maintain computable mirrors (`CompPoly`, `CRat`, `ModPoly`, `CompTPS`) and a boundary map `CompPoly.toMathlib` (coherence lemmas are stated but not yet proved). Integer and `ZMod p` arithmetic requires no mirror: kernel `Int` and `decide` suffice.

**Icon parity.** The computable layer follows Icon's algorithms literally—not Mathlib's canonical division—because the validation criterion is reproduction of the 1986 benchmark output. This entailed several non-obvious implementation choices:

- **`div_poly` / `mod_poly`:** Quotient steps accumulate a single term `qterm`, then subtract `qterm * b` (not `q * b` from a running quotient polynomial).
- **`EUCLID`:** Extended gcd state is \((a_1, a_2, s_1, s_2, t_1, t_2)\) with initial \((A, B, 1, 0, 0, 1)\); `INVERSE` calls `EUCLID(b, a)` (modulus first).
- **`MOD_RS`:** Recursive remainder sequence; constant-divisor early exits in `div` affect intermediate term shapes.
- **`S_PRS`:** `subReduce` short-circuits when `prem` is already zero (Icon behaviour).
- **`base_B`:** Digit lists are MSB-first after LSB accumulation and reverse.
- **Printing:** `Print.lean` reimplements Icon's `print_*` family so stdout is diffable, not `Repr`.

Architecture notes are consolidated in `Computability.lean`.

### 4.2 Module correspondence

| Report section | Proof layer | Computable / report layer |
|----------------|-------------|---------------------------|
| §2 domain types | `Types.lean`, `Domains.lean` | — |
| §2 `base_B` | — | `BaseB.lean` |
| `GCD`, `EUCLID`, `INVERSE` | `Euclidean.lean`, `Gcd.lean` | `ComputableAlg.lean` (`euclid`, `inverse`), `ModPoly` |
| `CRA1`, `CRA2`, `CRA` | `Congruence.lean` | same (kernel `Int`) |
| `DIOPHANTINE` | `Diophantine.lean` | same |
| `MOD_RS`, `PREM`, `E_PRS`, `S_PRS` | `Polynomial.lean` | `ComputablePoly.lean`, `ComputableAlg.lean` |
| `NIA` | `Interpolation.lean` | `CompPoly.nia` in `ComputableAlg.lean` |
| `FFT`, `FFI` | `Fft.lean` | `CompPoly.fftCoeffs`, `CompPoly.ffi` |
| `NPSI` | `PowerSeries.lean` | `ComputableTPS.lean` |
| Icon printing | — | `Print.lean` |
| Full benchmark | — | `Report.lean` |
| Architecture | `Computability.lean` | — |
| Regression tests | — | `Tests.lean` |

---

## 5. Verification and Trust

We classify each component by epistemic status. The 1986 report lists fourteen application procedures; there is **no `CDF`** in that suite. The congruence stack is **`CRA1` / `CRA2` / `CRA`** (Chinese remainder).

### 5.1 Trust tiers

| Tier | Meaning | Examples |
|------|---------|----------|
| **A — Mathlib theorem** | Definition delegates to a proved Mathlib fact | `euclid_bezout` via `EuclideanDomain.gcd_eq_gcd_ab`; `euclidInt_bezout` via `Int.gcd_eq_gcd_ab`; polynomial ring laws in `Domains.lean` |
| **B — Regression + report parity** | Icon-faithful computable code; outputs match `tests.icn` / `Tests.lean` | `CompPoly.div`, `modRS`, `ePRS`, `sPRS`, `fftCoeffs`, `ffi`, `nia`, `BaseB` |
| **C — Stated coherence targets (not yet proved)** | Proof layer and computable layer should coincide | `CompPoly.toMathlib` homomorphism lemmas; `gcd` / `mod` / `euclid` coherence |

Most of the port sits in tier B. The immediate milestone was reproducing the 1986 experimental package, not certifying every Lipson procedure against Mathlib's canonical polynomial API.

### 5.2 Procedure-by-procedure analysis

**GCD / EUCLID.** On integers, Mathlib supplies `Int.gcd`, `Int.gcdA`, `Int.gcdB` and Bézout's lemma; this package adds thin report-shaped wrappers and printing. On ℚ\([x]\) and GF\((p)\)\([x]\), Mathlib has `EuclideanDomain.gcd`, but `CompPoly.gcd` / `ModPoly.gcd` are separate Icon-style Euclidean loops with fuel bounds, checked against Icon tables but not yet proven equal to `EuclideanDomain.gcd` via `toMathlib`. Fuel-guarded partial definitions can diverge on pathological inputs; for report inputs they agree.

**INVERSE.** Modular integers reduce to Mathlib extended gcd. Polynomial inverse is not a named Mathlib API; the package adds a concrete, testable procedure matching the 1986 benchmarks.

**CRA / DIOPHANTINE.** Mathlib has Chinese remainder theorems in commutative algebra but not the Lipson/Ericson recursive `CRA1` procedure, `CRA2` pairwise glue, or list-shaped `CRA` driver with Icon `mod` semantics. Correctness is classical number theory, validated by `native_decide` on report congruence tables, not formalized as theorems.

**PRS family.** The package adds pseudo-remainder, remainder sequences, `E_PRS`, and Collins–Brown `S_PRS`—standard computer-algebra algorithms from Lipson, implemented in both proof and eval layers. Neither gcd correctness of the last nonzero subresultant nor equivalence with Mathlib's `EuclideanDomain.gcd` is proved. `MOD_RS` is pedagogical (coefficient swell); trust rests on full report parity and targeted coefficient checks.

**FFT / FFI.** Not present in Mathlib as a Cooley–Tukey API. No proof that `fftCoeffs` implements a DFT or that `ffi` recovers the unique interpolating polynomial. Correctness assumes a suitable root of unity ω and that `inverse(omega)` exists—the same implicit preconditions as the 1986 Icon code. `FFI` depends on `INVERSE`; modular or polynomial inverse bugs propagate.

**NIA / NPSI.** Newton interpolation and truncated Newton power-series inversion are added as standalone definitions; Mathlib has related infrastructure but not these exact procedures.

**`base_B` / printing.** Entirely package-specific; integration infrastructure for report diffing, not mathematics.

### 5.3 Summary: Mathlib versus this formalization

| Procedure | In Mathlib (directly usable)? | Contribution of this work |
|-----------|------------------------------|---------------------------|
| `GCD` / `EUCLID` on ℤ | Yes | Report API, printing, tables |
| `GCD` / `EUCLID` on ℚ\([x]\), GF\((p)\)\([x]\) | Yes (abstract) | Icon-faithful computable gcd/euclid + report parity |
| `INVERSE` on ℤ | Yes (via `gcdB`) | Icon argument order, `Option` + error strings |
| `INVERSE` on polynomials | No single matching API | Full procedure + tests |
| `CRA1` / `CRA2` / `CRA` | CRT theory only | Exact recursive Icon algorithms + `iconMod` |
| `DIOPHANTINE` | No | Composition of gcd + `CRA1` |
| `MOD_RS` / `PREM` / `E_PRS` / `S_PRS` | No | Full PRS suite (proof + computable) |
| `NIA` | No | Newton interpolation |
| `FFT` / `FFI` | No | Cooley–Tukey + interpolation pipeline |
| `NPSI` | Partial | Newton truncated iteration as in report |
| `base_B` | No | Digit-vector arithmetic for §2 tables |
| Icon stdout | No | `Print.lean`, `Report.lean`, comparison tooling |

For integers, the package is convenience and reproduction atop Mathlib. For polynomial remainder sequences, CRA/Diophantine drivers, FFT/FFI, and the computable eval layer, it adds substantial code Mathlib does not offer out of the box.

---

## 6. Experimental Validation

The 1986 package validated algorithms by printing exhaustive tables. We replicate this methodology at two granularities.

**Unit-level checks.** `Tests.lean` uses `native_decide` on coefficients and congruences for the report's §3.1–§3.2 examples.

**End-to-end report parity.** Icon `tests.icn` `main()` and Lean `lake exe iconReport` emit the same 85-line stdout after normalizing timing metadata and a few EUCLID fraction parenthesizations. A line-by-line comparison script maps `[N msecs]` → `[0 msecs]`. This integration test exercises proof layer, computable layer, and printing together.

| Report section | Example | Validation |
|----------------|---------|------------|
| §2 | `base_B` add/mul/div tables | report diff |
| §3.1.1 | `EUCLID(84, 54) = (6, 2, -3)` | `native_decide` + report |
| §3.1.2 | `INVERSE` table (ℤ, ℚ\([x]\), GF(2)\([x]\)) | `native_decide` + report |
| §3.1.3 | `CRA1`, `CRA2`, `CRA` (incl. \(u(x) = 183 + 238x\)) | `native_decide` + report |
| §3.1.4 | Diophantine particular solutions | `native_decide` + report |
| §3.2.1 | `MOD_RS` six-term sequence | `native_decide` + report |
| §3.2.2 | `PREM` rows | `native_decide` + report |
| §3.2.3–§3.2.4 | `E_PRS`, `S_PRS` | `native_decide` + report |
| §3.3 | `NIA`, `FFT`, `FFI`, `NPSI` | `native_decide` + report |

---

## 7. Omissions

Per the report itself, we omit utilities that are not mathematical core:

- Runtime **dispatch** (`div`, `mod`, … by domain type) — replaced by Lean typeclasses and fixed modules.
- **Timer** fidelity (`settime` / `showtime`, §3.4) — Lean prints `[0 msecs]`; comparison tooling normalizes Icon timing lines.
- Full **verified** base-\(B\) long arithmetic — `BaseB` reproduces benchmarks via `Nat`, not a proved digit-ring.

---

## 8. Conclusion and Future Work

The 1986 Icon package validated algorithms on selected inputs and printed exhaustive tables. The Lean port automates the same validation: unit tests via `native_decide`, full report diff across 85 lines. All fourteen Section 3 application algorithms are implemented without `sorry`. Section 2 domain types use Mathlib instances; `base_B` and Icon printing are reproduced for parity.

**Provability status.** Integer gcd/Euclid is anchored in Mathlib theorems. The polynomial PRS family, FFT/FFI, and the `CompPoly` computable mirror are regression-trusted—the same epistemic boundary the 1986 Icon package observed.

**Future work.** Coherence proofs linking computable and proof layers (`toMathlib` for `CompPoly` / `CompTPS`); semantic theorems (CRA satisfies congruences; `S_PRS` gcd correctness; FFT/FFI interpolation identity). Lean makes these obligations precise; this formalization lays down canonical definitions and Icon-faithful executables side by side, without prematurely replacing the latter with Mathlib calls that would break historical parity.

---

## References

1. Lars Warren Ericson, *An ICON Package for Experimenting with Euclidean Domains*, NYU Computer Science Technical Report #232, August 1986.
2. John Lipson, *Elements of Algebra and Algebraic Computing*, Benjamin/Cummings, 1981.
3. Technical Report #232, Section 1: *Introduction & Programming with Euclidean Domains*.
4. Technical Report #232, Section 2: *Euclidean domains: representation and basic arithmetic*.
5. Technical Report #232, Section 3: *Algorithms for various problems over Euclidean domains*.
