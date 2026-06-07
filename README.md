# icon2lean

Translation of a 1986 Icon package (Courant Institute technical report CS-TR #232) into Lean 4 with Mathlib. The source report is [`Courant_Ericson_1986.pdf`](Courant_Ericson_1986.pdf); the article-style walkthrough is [`icon2lean.md`](icon2lean.md).

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

Lean’s toolchain can feel opaque because three separate pieces work together: **elan** (installer), **Lake** (build tool), and **Mathlib** (a huge dependency). The steps below are the same ones used to set up this project on Linux.

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

Lake is Lean’s package manager (similar to `cargo` or `npm`). This step clones Mathlib into `.lake/packages/`:

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
- `MOD_RS` on the report's QZ[x] inputs (length 6, intermediate terms, final 0)
- `PREM` field remainder (`1818 - 1305x + 846x²`)

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

## Module map (Icon algorithms → Lean)

| Report name | Lean file | Main definitions |
|-------------|-----------|------------------|
| GCD, EUCLID, INVERSE | `Icon2lean/Gcd.lean` | `gcdInt`, `euclidInt`, `modularInverse` |
| CRA1, CRA2, CRA | `Icon2lean/Congruence.lean` | `cra1`, `cra2`, `cra` |
| DIOPHANTINE | `Icon2lean/Diophantine.lean` | `diophantine` |
| PREM, MOD_RS, E_PRS, S_PRS | `Icon2lean/Polynomial.lean` | `prem`, `modRS`, `ePRS`, `sPRS` |
| NIA | `Icon2lean/Interpolation.lean` | `newtonInterpolation` |
| FFT, FFI | `Icon2lean/Fft.lean` | `fftCoeffs`, `ffi` |
| NPSI | `Icon2lean/PowerSeries.lean` | `npsi`, `npsiTpower` |

---

## Contributions and Collaboration

This repository functions strictly as a unilateral broadcast of public code for educational and research purposes.

* **Pull Requests and Issues:** This project does not accept external Pull Requests, code contributions, or modifications, and tracking features have been disabled. Any external collaboration vectors are closed.
* **Forks:** Users are entirely free and encouraged to fork or clone this repository to modify the code on their own profiles in accordance with the repository's Apache 2.0 License.

## Regulatory and Liability Disclaimer

* **Limitations:** The code provided herein is for theoretical research and academic simulation purposes only.
* **Liability Protection:** In accordance with Section 8 of the Apache 2.0 License, this software is provided "AS IS" without warranties of any kind. Catskills Research Company disclaims all liability for any direct, indirect, or consequential damages resulting from the use, misuse, or deployment of this simulation code.
