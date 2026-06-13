# icon2lean

Translation of a 1986 Icon package (Courant Institute technical report CS-TR #232) into Lean 4 with Mathlib. The source report is [`Courant_Ericson_1986.pdf`](Courant_Ericson_1986.pdf); the paper-style treatment is [`arxiv.md`](arxiv.md).

---

# Translating Euclidean domain algorithms from 1986 Icon to 2026 Lean 4

In August 1986, at New York University's Courant Institute of Mathematical Sciences, I authored NYU Computer Science Technical Report #232: **"An ICON Package for Experimenting with Euclidean Domains"** [1]. The goal was to responsibly implement algorithms over mathematical structures like integers, quotient rings, polynomials, and power series, following John Lipson's text, *Elements of Algebra and Algebraic Computing* [1, 2].

At the time, an attractive programming language for this task was **Icon** [1, 2]. Icon lacked native typeclasses or object-oriented dispatch [2]. To implement generic division and arithmetic operations across distinct domains, I built a custom runtime dispatch system using string reflection [2].

This repository contains a **Lean 4 port** of the report's domain types (Section 2) and application algorithms (Section 1.2 / Section 3), with **no `sorry`s**. Source Icon and OCR'd listings live in [`Courant_Ericson_1986.md`](Courant_Ericson_1986.md); the executable port lives in [`Icon2lean/`](Icon2lean/). A copy of the original report is in [`Courant_Ericson_1986.pdf`](Courant_Ericson_1986.pdf).

> **Notation.** Icon listings follow the report's *fancy notation* (Section 1.3 of [1]): `©` is division, `®` is addition, `—` is subtraction, `F (args) <= body ■` is a procedure definition, and `■` marks return.

---

## What we built (and why it is structured this way)

The 1986 package had three jobs at once: represent Euclidean domains, run algorithms on them, and **print** benchmark tables in a fixed Icon format. The Lean port separates those concerns deliberately.

### Three layers

| Layer | Role | Key modules |
|-------|------|-------------|
| **Proof / canonical** | Mathlib-backed types and noncomputable definitions suitable for theorems | `Types.lean`, `Domains.lean`, `Euclidean.lean`, `Polynomial.lean`, `Fft.lean`, `Congruence.lean`, … |
| **Computable / eval** | Mirrors that `#eval`, `native_decide`, and `lake exe` can actually reduce | `ComputablePoly.lean`, `ComputableAlg.lean`, `ComputableTPS.lean`, `BaseB.lean` |
| **Report / print** | Icon-style formatters and the full `tests.icn` benchmark driver | `Print.lean`, `Report.lean` |

**Design choice:** Mathlib's `Polynomial ℚ`, `TruncPowerSeries`, and `EuclideanDomain.gcd` are the right *mathematical* objects, but they are **noncomputable** — the kernel cannot evaluate them for regression tests. So we maintain computable mirrors (`CompPoly`, `CRat`, `ModPoly`, `CompTPS`) and a single boundary map `CompPoly.toMathlib` (coherence lemmas are listed but not yet proved). Integer and `ZMod p` arithmetic needs no mirror: kernel `Int` / `decide` suffices.

**Icon parity choice:** The computable layer follows Icon's algorithms literally — not Mathlib's canonical division — because the goal was *reproducing the 1986 benchmark output*. That forced several non-obvious fixes:

* **`div_poly` / `mod_poly`:** Quotient steps accumulate a **single term** `qterm`, then subtract `qterm * b` (not `q * b` from a running quotient polynomial).
* **`EUCLID`:** Extended gcd state is `(a₁, a₂, s₁, s₂, t₁, t₂)` with initial `(A, B, 1, 0, 0, 1)`; `INVERSE` calls `EUCLID(b, a)` (modulus first).
* **`MOD_RS`:** Recursive remainder sequence; constant-divisor early exits in `div` matter for intermediate term shapes.
* **`S_PRS`:** `subReduce` short-circuits when `prem` is already zero (Icon behaviour).
* **`base_B`:** Digit lists are MSB-first after LSB accumulation and reverse.
* **Printing:** `Print.lean` reimplements Icon's `print_*` family (`integer`, `zInt`, `qRat`, `compPoly`, `diophantineLine`, …) so stdout is diffable, not `Repr`.

Architecture notes live in [`Icon2lean/Computability.lean`](Icon2lean/Computability.lean).

### Report parity workflow

Icon `tests.icn` `main()` and Lean `lake exe iconReport` now emit the **same 85-line stdout** (after normalizing timing and a few EUCLID fraction parens):

```bash
./run_report.sh          # Icon (needs `icon` interpreter)
./run_lean_report.sh     # Lean
python3 compare_reports.py
```

| Script | What it runs |
|--------|----------------|
| [`run_report.sh`](run_report.sh) | Bundles Icon via `compare_tests.bundle_icon`, prints stdout only |
| [`run_lean_report.sh`](run_lean_report.sh) | `lake exe iconReport` |
| [`compare_reports.py`](compare_reports.py) | Line-by-line diff; maps `[N msecs]` → `[0 msecs]` |

Unit-level checks remain in [`Icon2lean/Tests.lean`](Icon2lean/Tests.lean) (`native_decide` on coefficients and congruences). The report scripts are the end-to-end integration test: proof layer + computable layer + printing together.

```bash
lake update    # first clone only
lake build     # typechecks everything; zero sorry
lake build Icon2lean.Tests
lake exe iconReport
```

---

## Lean library map

| Report | Proof layer | Computable / report layer |
|--------|-------------|---------------------------|
| §2 domain types | [`Types.lean`](Icon2lean/Types.lean), [`Domains.lean`](Icon2lean/Domains.lean) | — |
| §2 `base_B` | — | [`BaseB.lean`](Icon2lean/BaseB.lean) |
| `GCD`, `EUCLID`, `INVERSE` | [`Euclidean.lean`](Icon2lean/Euclidean.lean), [`Gcd.lean`](Icon2lean/Gcd.lean) | [`ComputableAlg.lean`](Icon2lean/ComputableAlg.lean) (`euclid`, `inverse`), [`ModPoly`](Icon2lean/ComputableAlg.lean) for `GF(p)[x]` |
| `CRA1`, `CRA2`, `CRA` | [`Congruence.lean`](Icon2lean/Congruence.lean) | same (kernel `Int`) |
| `DIOPHANTINE` | [`Diophantine.lean`](Icon2lean/Diophantine.lean) | same |
| `MOD_RS`, `PREM`, `E_PRS`, `S_PRS` | [`Polynomial.lean`](Icon2lean/Polynomial.lean) | [`ComputablePoly.lean`](Icon2lean/ComputablePoly.lean), [`ComputableAlg.lean`](Icon2lean/ComputableAlg.lean) |
| `NIA` | [`Interpolation.lean`](Icon2lean/Interpolation.lean) | `CompPoly.nia` in [`ComputableAlg.lean`](Icon2lean/ComputableAlg.lean) |
| `FFT`, `FFI` | [`Fft.lean`](Icon2lean/Fft.lean) | `CompPoly.fftCoeffs`, `CompPoly.ffi` |
| `NPSI` | [`PowerSeries.lean`](Icon2lean/PowerSeries.lean) | [`ComputableTPS.lean`](Icon2lean/ComputableTPS.lean) |
| Icon printing | — | [`Print.lean`](Icon2lean/Print.lean) |
| Full benchmark | — | [`Report.lean`](Icon2lean/Report.lean) → `lake exe iconReport` |
| Architecture | [`Computability.lean`](Icon2lean/Computability.lean) | — |
| Regression tests | — | [`Tests.lean`](Icon2lean/Tests.lean) |

### Verified examples (report §3)

| Section | Example | How checked |
|---------|---------|-------------|
| §2 | `base_B` add/mul/div tables | report diff |
| §3.1.1 | `EUCLID(84, 54) = (6, 2, -3)` | `native_decide` + report |
| §3.1.2 | `INVERSE` table (`ℤ`, `ℚ[x]`, `GF(2)[x]`) | `native_decide` + report |
| §3.1.3 | `CRA1`, `CRA2`, `CRA` (incl. polynomial `u(x) = 183 + 238x`) | `native_decide` + report |
| §3.1.4 | Diophantine particular solutions | `native_decide` + report |
| §3.2.1 | `MOD_RS` six-term sequence | `native_decide` + report |
| §3.2.2 | `PREM` rows (incl. huge-int row 1 → `0`) | `native_decide` + report |
| §3.2.3–§3.2.4 | `E_PRS`, `S_PRS` | `native_decide` + report |
| §3.3 | `NIA`, `FFT`, `FFI`, `NPSI` | `native_decide` + report |

---

## Part 1: Domain types (Section 2)

The report's **quotient Euclidean domain** is a **Euclidean domain** in Mathlib (`EuclideanDomain`).
Primitive domains are `ℤ` and `ℚ`. Three constructors build new domains:

| Constructor | Report | Lean type |
|-------------|--------|-----------|
| modular `D/(e)` | `modulo(item, modulus)` | `ModularDomain R I` or `ModularInt n` (= `ZMod n`) |
| polynomial `D[x]` | `poly(terms)` | `PolyDomain R` (= `Polynomial R`) |
| truncated series `T(D[[x]])ₙ` | `tpower(poly, N)` | `TruncPowerSeries R n` (= `R[x]/(Xⁿ)`) |

Formal power series `D[[x]]` use `PowerSeries R` (for `NPSI` inversion); they are not Euclidean domains.

* **`ℤ`:** `Int` / notation `ℤ`. `EuclideanDomain ℤ`.
* **`ℚ`:** `Rat` / notation `ℚ`. `Field ℚ` → `EuclideanDomain ℚ`.
* **Modular:** `Ideal.Quotient.mk` for general quotients; `ZMod.unitOfCoprime` for units. No `LinearOrder` on `ZMod n` (matches the report's `<0_modulo` always false).
* **Polynomial:** `Polynomial.degree : WithBot ℕ` (`⊥` = report's `"-∞"` for zero). `EuclideanDomain (Polynomial F)` when `F` is a field.
* **Truncated series:** `truncatePoly n p` = multiply-then-truncate in `R[x]/(Xⁿ)`.

**`base_B`:** The report's variable-base digit arithmetic (§2.2) is not Mathlib infrastructure. For benchmark parity we added [`BaseB.lean`](Icon2lean/BaseB.lean): digit vectors, `toNat` / `ofNat`, and `add` / `sub` / `mul` / `div` via natural conversion. This is a **computable report helper**, not a verified arbitrary-precision base‑\(B\) ring.

---

## Part 2: Application algorithms (Section 3)

Fourteen algorithms from Section 1.2 of [1]. Proof-layer definitions are generic over `EuclideanDomain` or `Polynomial R` where possible; the computable layer reimplements Icon control flow for `ℚ[x]`, `ℤ/pℤ[x]`, and truncated series.

### §3.1.1 — `GCD` and `EUCLID`

* **Icon `GCD`:** recursive `GCD(b, mod(a,b))` until `b = 0`.
* **Icon `EUCLID`:** extended gcd loop updating `(a, s, t)` triples.
* **Lean proof layer:** `euclideanGcd`, `euclid` on any `EuclideanDomain`; `euclidInt` / `euclidZ` on `ℤ` with `Int.gcdA` / `Int.gcdB`.
* **Lean computable layer:** `CompPoly.euclid`, `ModPoly.euclid` — Icon state machine with fuel guards.
* **Report example:** `EUCLID(84, 54) = [6, 2, -3]`.

### §3.1.2 — `INVERSE`

* **Icon:** `gst := EUCLID(m, a)` then `mod(div(gst[3], gst[1]), m)` when `unit(gst[1])`.
* **Lean:** `modularInverse` on `ℤ`; `CompPoly.inverse` / `ModPoly.inverse` on polynomial domains.
* Argument order **`EUCLID(m, a)`** is easy to get wrong; the Lean port matches Icon exactly.

### §3.1.3 — `CRA1`, `CRA2`, `CRA`

* **Icon:** recursive `CRA1`; `CRA2` and `CRA` built from `INVERSE` and `mod`.
* **Lean:** [`Congruence.lean`](Icon2lean/Congruence.lean) — uses `iconMod` (`Int.emod`) for Icon's non-negative remainder convention.
* **Report examples:** scalar CRA table; polynomial CRA yielding `u(x) = 183 + 238x`.

### §3.1.4 — `DIOPHANTINE`

* **Icon:** `EUCLID` + `CRA1` branch on `|b| < |a|`.
* **Lean:** [`Diophantine.lean`](Icon2lean/Diophantine.lean).

### §3.2.1 — `MOD_RS`

* **Icon:** `MOD_RS(a,b) = [a] || MOD_RS(b, mod(a,b))`.
* **Lean proof:** `Polynomial.modRS`; computable: `CompPoly.modRS`.
* **Report:** six-term `ℚ[x]` sequence ending in `0`.

### §3.2.2 — `PREM`

* **Icon:** scale by `lead_coef(q)^(deg_diff+1)`, then `rem`.
* **Lean:** `prem` in both layers.

### §3.2.3–§3.2.4 — `E_PRS` and `S_PRS`

* **Icon:** `E_PRS` uses `PREM`; `S_PRS` is Collins–Brown subresultant PRS.
* **Lean:** `ePRS`, `sPRS` in both layers.

### §3.3.1 — `NIA`

* Newton interpolation on point lists.
* **Lean:** `newtonInterpolation` (proof); `CompPoly.nia` (eval).

### §3.3.2 — `FFT` and `FFI`

* **Icon `FFT`:** Cooley–Tukey decimation on even/odd coefficient splits.
* **Icon `FFI`:** `polynomialize` → `FFT` with `inverse(omega)` → scale by `1/N`.
* **Lean:** `evenTerms` / `oddTerms` / `fftCoeffs` / `ffi` in [`Fft.lean`](Icon2lean/Fft.lean); computable twins on `List CRat`.

### §3.3.3 — `NPSI`

* Newton truncated power-series inversion.
* **Lean:** `npsi`, `npsiTrunc` (proof); `CompTPS.npsi` (eval).

---

## Provability, trust, and what Mathlib already gives you

This section answers: *which algorithms are mathematically anchored, which are only regression-tested, and whether this package duplicates Mathlib or adds something new.*

> **Note on names:** The 1986 report lists fourteen application procedures; there is **no `CDF`** in that suite. The congruence stack is **`CRA1` / `CRA2` / `CRA`** (Chinese remainder). Below, "CRA" refers to those.

### Trust tiers

| Tier | Meaning | Examples in this repo |
|------|---------|------------------------|
| **A — Mathlib theorem** | Definition delegates to a proved Mathlib fact | `euclid_bezout` via `EuclideanDomain.gcd_eq_gcd_ab`; `euclidInt_bezout` via `Int.gcd_eq_gcd_ab`; polynomial ring laws in `Domains.lean` |
| **B — Regression + report parity** | Icon-faithful computable code; outputs match `tests.icn` / `Tests.lean` | `CompPoly.div`, `modRS`, `ePRS`, `sPRS`, `fftCoeffs`, `ffi`, `nia`, `BaseB` |
| **C — Stated coherence targets (not yet proved)** | Proof layer and computable layer should coincide | `CompPoly.toMathlib` homomorphism lemmas; `gcd` / `mod` / `euclid` coherence |

Most of the port sits in **tier B**. That is intentional: the immediate milestone was *reproducing the 1986 experimental package*, not certifying every Lipson procedure against Mathlib's canonical polynomial API.

### Algorithm-by-algorithm commentary

#### `GCD` / `EUCLID`

* **Integers:** Mathlib supplies `Int.gcd`, `Int.gcdA`, `Int.gcdB` and Bézout's lemma. This package adds thin report-shaped wrappers (`euclidInt`, `gcdInt`) and printing — **not a new algorithm**.
* **Polynomials (`ℚ[x]`, `GF(p)[x]`):** Mathlib has `EuclideanDomain.gcd` on `Polynomial F` when `F` is a field. The package's `CompPoly.gcd` / `ModPoly.gcd` are **separate Icon-style Euclidean loops** with fuel bounds. They are checked against Icon tables and the full report, but **not yet proven equal** to `EuclideanDomain.gcd` via `toMathlib`.
* **What is concerning:** Fuel-guarded partial definitions can diverge from Mathlib on pathological inputs (huge degree, zero leading coefficients mid-division). For report inputs they agree.

#### `INVERSE`

* **Modular integers:** Reduces to Mathlib extended gcd (`gcdB`). The package adds Icon's `ERROR:` path and `iconMod` normalization — **API and convention**, not new mathematics.
* **Polynomial inverse:** Icon's `INVERSE(a, m)` on `ℚ[x]` / `GF(2)[x]` is **not** a named Mathlib tactic. Mathlib gives units and field inverses in abstract rings; it does not expose this exact "extended gcd then divide by constant gcd" recipe as a user-facing `INVERSE`. The package **adds value** as a concrete, testable procedure matching the 1986 benchmarks.

#### `CRA` / `DIOPHANTINE`

* Mathlib has Chinese remainder **theorems** and infrastructure in commutative algebra, but **not** the Lipson/Ericson recursive `CRA1` procedure, `CRA2` pairwise glue, or list-shaped `CRA` driver with Icon `mod` semantics.
* `diophantine` is likewise **not** a Mathlib named function; it is a small composition of `Int.gcd` + `cra1`.
* **Trust:** Correctness for CRA is classical number theory; here it is validated by `native_decide` on the report's congruence tables, not formalized as theorems (`cra2_satisfies_both_congruences`, etc.).

#### `MOD_RS`, `PREM`, `E_PRS`, `S_PRS` (the PRS family)

This is the **most algebraically subtle** part of the suite and the farthest from "already in Mathlib."

* Mathlib provides polynomial `%` and `EuclideanDomain.gcd` over fields. It does **not** ship:
  * pseudo-remainder (`PREM`) as used in integral polynomial gcd,
  * remainder sequences based on `%` (`MOD_RS`) — with **intermediate coefficient swell**,
  * `E_PRS` (Euclidean PRS with pseudo-remainders),
  * Collins–Brown **`S_PRS`** subresultant PRS.
* The package **adds real value**: these are standard computer-algebra algorithms from Lipson's book, implemented twice (proof-layer `Polynomial.lean`, eval-layer `ComputableAlg.lean`).
* **What is concerning for proofs:**
  * **`MOD_RS`** is pedagogical; it is not the method you would use in production gcd (swell, then normalize at the end).
  * **`E_PRS` / `S_PRS`** are the usual gcd engines over `ℤ[x]` / `ℚ[x]` in theory, but this repo proves **neither** that the last nonzero term is a gcd **nor** that `S_PRS` matches Mathlib's `EuclideanDomain.gcd`.
  * Coherence between `prem` in the two layers is assumed, not proved.
* **Trust today:** Full report parity on the benchmark polynomials; targeted `native_decide` coefficient checks in `Tests.lean`.

#### `FFT` / `FFI`

* **Not in Mathlib** (no Cooley–Tukey FFT or fast interpolation API on polynomial coefficients in the library we depend on).
* The package **adds the entire algorithm** — twice (`Fft.lean` on `Polynomial R`, `CompPoly.fftCoeffs` / `ffi` for evaluation).
* **What is concerning:**
  * No proof that `fftCoeffs` implements a DFT or that `ffi` recovers the unique interpolating polynomial of degree `< N`.
  * Correctness assumes a suitable root of unity `ω` and that `inverse(omega)` exists — the same implicit preconditions as the 1986 Icon code.
  * `FFI` **depends on `INVERSE`** for `ω`; any modular/polynomial inverse bug propagates here.
  * Only tiny instances are tested (`N = 2` in `Tests.lean`); the report's larger `FFI` line is output parity, not a formal spec.
* **Value:** Preserves the Lipson-level "experiment with Euclidean domains + FFT" story; not a substitute for a proved numeric FFT library.

#### `NIA` / `NPSI`

* **`NIA`:** Newton interpolation — Mathlib has polynomial evaluation and division, but not this Newton basis procedure as a standalone definition. Package adds it; tested on small point lists.
* **`NPSI`:** Mathlib has `PowerSeries` and inversion lemmas (`invOfUnit`, etc.). The report's **Newton doubling iteration truncated at `X^N`** (`npsiStep`, `npsi`) is **not** exposed as a ready-made Mathlib function. The package adds the Icon procedure; `CompTPS.npsi` mirrors it for `#eval`.

#### `base_B` / printing / report driver

* **Entirely package-specific.** Mathlib does not provide Icon digit vectors or the `print_Q` / `compPoly` formatting rules.
* **`Print.lean` + `Report.lean`** are what make `compare_reports.py` possible; they are integration infrastructure, not mathematics.

### Summary: Mathlib vs this package

| Procedure | In Mathlib (directly usable)? | What this package adds |
|-----------|------------------------------|-------------------------|
| `GCD` / `EUCLID` on `ℤ` | Yes — `Int.gcd`, `gcdA`, `gcdB`, `EuclideanDomain` | Report API, printing, tables |
| `GCD` / `EUCLID` on `ℚ[x]`, `GF(p)[x]` | Yes — abstract `EuclideanDomain.gcd` | Icon-faithful **computable** gcd/euclid + report parity |
| `INVERSE` on `ℤ` | Yes — via `gcdB` | Icon argument order, `Option` + error strings |
| `INVERSE` on polynomials | No single matching API | Full procedure + tests |
| `CRA1` / `CRA2` / `CRA` | CRT theory only | Exact recursive Icon algorithms + `iconMod` |
| `DIOPHANTINE` | No | Composition of gcd + `CRA1` |
| `MOD_RS` / `PREM` / `E_PRS` / `S_PRS` | No | Full PRS suite (proof + computable) |
| `NIA` | No | Newton interpolation |
| `FFT` / `FFI` | No | Cooley–Tukey + interpolation pipeline |
| `NPSI` | Partial — power series inverse theory | Newton truncated iteration as in report |
| `base_B` | No | Digit-vector arithmetic for §2 tables |
| Icon stdout | No | `Print.lean`, `Report.lean`, `compare_reports.py` |

**Bottom line:** For integers, the package is mostly **convenience and reproduction** on top of Mathlib. For polynomial remainder sequences, CRA/Diophantine drivers, FFT/FFI, and the computable eval layer, the package **adds substantial code Mathlib does not offer out of the box**. The next step is to **prove** tier-B algorithms correct (or equivalent to Mathlib) via `toMathlib` coherence — not to replace them with Mathlib calls blindly, which would break Icon parity.

---

## What is intentionally omitted

Per the report itself, we omit utilities that are not mathematical core:

* Runtime **dispatch** (`div`, `mod`, … by domain type) — replaced by Lean typeclasses and fixed modules.
* **Timer** fidelity (`settime` / `showtime`, §3.4) — Lean prints `[0 msecs]`; `compare_reports.py` normalizes Icon timing lines.
* Full **verified** base‑\(B\) long arithmetic — `BaseB` is for benchmark reproduction via `Nat`, not a proved digit-ring.

---

## Conclusion

The 1986 package validated algorithms on selected inputs and printed exhaustive tables. The Lean port now does the same automatically:

1. **Unit tests** in [`Icon2lean/Tests.lean`](Icon2lean/Tests.lean) (`native_decide` on coefficients and congruences).
2. **Full report diff** via [`run_report.sh`](run_report.sh), [`run_lean_report.sh`](run_lean_report.sh), and [`compare_reports.py`](compare_reports.py) — **85 lines, matching**.

All fourteen Section 3 application algorithms are implemented without `sorry`. Section 2 domain types use Mathlib instances; `base_B` and Icon printing are reproduced for parity.

**Provability status:** Integer gcd/Euclid is anchored in Mathlib theorems. The polynomial PRS family, FFT/FFI, and the `CompPoly` computable mirror are **regression-trusted** — concerning if you need production computer algebra, but exactly where the 1986 Icon package also stopped short of proof.

**Next step:** Coherence proofs linking computable and proof layers (`toMathlib` for `CompPoly` / `CompTPS`), then semantic theorems (CRA satisfies congruences; `S_PRS` gcd correctness; FFT/FFI interpolation identity). Lean makes that possible; this port lays down both the canonical definitions and the Icon-faithful executables side by side.

### References

* [1] Lars Warren Ericson, *"An ICON Package for Experimenting with Euclidean Domains"*, NYU CS TR #232, August 1986. ([`Courant_Ericson_1986.md`](Courant_Ericson_1986.md))
* [2] Technical Report #232, Section 1: *Introduction & Programming with Euclidean Domains*.
* [3] Technical Report #232, Section 2: *Euclidean domains: representation and basic arithmetic*.
* [4] Technical Report #232, Section 3: *Algorithms for various problems over Euclidean domains*.

---

## What is in the repo vs. what appears after you build

**Committed (small, human-readable):**

| Path | Purpose |
|------|---------|
| `lean-toolchain` | Pins Lean **4.30.0** (read by [elan](#1-install-elan-lean-version-manager)) |
| `lakefile.toml` | Project config; declares Mathlib **v4.30.0** as a dependency |
| `lake-manifest.json` | Lockfile: exact Git commits for Mathlib and its dependencies |
| `Icon2lean/` | Algorithm implementations (GCD, CRA, FFT, etc.) |
| `Icon2lean.lean` | Root module that imports the library |

**Generated locally (large, gitignored):**

| Path | Purpose | Typical size |
|------|---------|--------------|
| `.lake/packages/` | Downloaded Mathlib and helper libraries | ~7 GB |
| `.lake/build/` | Compiled `.olean` cache for this project | grows with builds |

If you see a multi-gigabyte `.lake/` folder after setup, that is normal. It is intentionally **not** in git.

---

## Lean setup (step by step)

Lean's toolchain can feel opaque because three separate pieces work together: **elan** (installer), **Lake** (build tool), and **Mathlib** (a huge dependency). The steps below are the same ones used to set up this project on Linux.

### 0. Prerequisites

- **git** — clone this repository  
- **curl** — install elan  
- **Disk space** — allow roughly **10 GB** free for Mathlib + build cache  
- **Time** — first `lake update` and `lake build` can take **10–30+ minutes** depending on CPU and network  

Optional but helpful: [Cursor](https://cursor.com/) or VS Code with the [Lean 4 extension](https://marketplace.visualstudio.com/items?itemName=leanprover.lean4).

### 1. Install elan (Lean version manager)

[elan](https://github.com/leanprover/elan) is like `rustup` for Rust: it installs Lean and switches versions per project.

```bash
curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh
```

When prompted, accept the default toolchain (you can press Enter). Then load elan into your current shell:

```bash
source "$HOME/.elan/env"
```

To make that permanent, the installer usually adds a line to `~/.bashrc` or `~/.profile`. Open a **new terminal** or run `source ~/.bashrc` before continuing.

Verify:

```bash
elan --version    # e.g. elan 4.2.2
which lake        # should print something like ~/.elan/bin/lake
```

You do **not** need to install Lean manually. elan reads `lean-toolchain` in this repo and downloads **Lean 4.30.0** the first time you run `lake`.

### 2. Clone and enter the project

```bash
git clone https://github.com/catskillsresearch/icon2lean.git
cd icon2lean
```

### 3. Download dependencies (`lake update`)

Lake is Lean's package manager (similar to `cargo` or `npm`). This step clones Mathlib into `.lake/packages/`:

```bash
lake update
```

What happens:

- Reads `lakefile.toml` → requests Mathlib tag `v4.30.0`  
- Writes/updates `lake-manifest.json` with exact commit hashes  
- Clones several GitHub repos under `.lake/packages/` (Mathlib pulls in batteries, aesop, etc.)

This is the slow, large download. Expect several gigabytes.

### 4. Build the project (`lake build`)

```bash
lake build
```

What happens:

- Compiles Mathlib modules your code imports (incremental; first run is heavy)  
- Typechecks all files under `Icon2lean/`  
- Produces cache files under `.lake/build/`  

A successful run ends with something like:

```text
Build completed successfully (1476 jobs).
```

### 5. Sanity-check with the report examples

```bash
lake env lean Icon2lean/Tests.lean
```

Or open `Icon2lean/Tests.lean` — all §3.1 report examples are checked with `native_decide`, and §3.2 polynomial examples via `ComputablePoly`:

- `EUCLID(84, 54)` → `(6, 2, -3)`
- `CRA1` / `CRA2` / `CRA` examples from the report
- `DIOPHANTINE` particular solutions `(1,-2)`, `(13,163)`, `(-11,6)`
- Polynomial CRA coefficients `a = 238`, `b = 183` → `u(x) = 183 + 238x`
- `MOD_RS` five-term sequence on the report's QZ[x] inputs
- `PREM` remainder `198 - 225x + 306x²`

### 6. Day-to-day commands

| Command | When to use |
|---------|-------------|
| `lake build` | After editing `.lean` files |
| `lake build Icon2lean` | Build only the library target |
| `lake clean` | Delete `.lake/build/` cache (keeps downloaded packages) |
| `rm -rf .lake && lake update && lake build` | Nuclear reset if dependencies get corrupted |

---

## Troubleshooting

**`lake: command not found`**  
Run `source "$HOME/.elan/env"` or open a new terminal after installing elan.

**Out of disk space during `lake update`**  
Mathlib needs several GB. Free space or use a machine with more storage; there is no lightweight subset for this project.

**Build runs out of memory**  
Close other apps; Mathlib compilation is RAM-heavy. Retry `lake build` (Lake resumes incrementally).

**Wrong Lean version**  
From the repo root, run `elan toolchain install leanprover/lean4:v4.30.0` then `lake build`. The file `lean-toolchain` should contain `leanprover/lean4:v4.30.0`.

**`.lake/` showed up in `git status`**  
It should be ignored. If git still tracks it, you may have added it before `.gitignore`; run `git rm -r --cached .lake` once (do not delete the folder on disk).

---

## Optional: regenerate the markdown from the PDF

The PDF→markdown script uses only Python stdlib plus system **mutool** (MuPDF):

```bash
# Debian/Ubuntu
sudo apt install mupdf-tools

mutool convert -F txt -o /tmp/mutool_full.txt Courant_Ericson_1986.pdf
python3 scripts/pdf_to_md.py /tmp/mutool_full.txt Courant_Ericson_1986.md
```

No Poetry or virtualenv is required unless you add Python dependencies later.

---

## Contributions and Collaboration

This repository functions strictly as a unilateral broadcast of public code for educational and research purposes.

* **Pull Requests and Issues:** This project does not accept external Pull Requests, code contributions, or modifications, and tracking features have been disabled. Any external collaboration vectors are closed.
* **Forks:** Users are entirely free and encouraged to fork or clone this repository to modify the code on their own profiles in accordance with the repository's Apache 2.0 License.

## Regulatory and Liability Disclaimer

* **Limitations:** The code provided herein is for theoretical research and academic simulation purposes only.
* **Liability Protection:** In accordance with Section 8 of the Apache 2.0 License, this software is provided "AS IS" without warranties of any kind. Catskills Research Company disclaims all liability for any direct, indirect, or consequential damages resulting from the use, misuse, or deployment of this simulation code.
