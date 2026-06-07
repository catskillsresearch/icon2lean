/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Algebra.Polynomial.Degree.Defs
import Mathlib.Algebra.Polynomial.Div

namespace Icon2lean

open Polynomial

/-- Even-powered sub-polynomial for FFT decimation (report §3.3.2). -/
noncomputable def evenTerms {R : Type*} [CommRing R] (p : Polynomial R) : Polynomial R :=
  (Finset.range (p.natDegree / 2 + 1)).sum fun i =>
    C (p.coeff (2 * i)) * X ^ i

/-- Odd-powered sub-polynomial for FFT decimation (report §3.3.2). -/
noncomputable def oddTerms {R : Type*} [CommRing R] (p : Polynomial R) : Polynomial R :=
  (Finset.range ((p.natDegree + 1) / 2)).sum fun i =>
    C (p.coeff (2 * i + 1)) * X ^ i

private def getCoeff {R : Type*} [CommRing R] (L : List R) (i : Nat) : R :=
  L.getD i 0

/-- Cooley–Tukey FFT on coefficient list (report §3.3.2 `FFT`). -/
noncomputable def fftCoeffs {R : Type*} [CommRing R] [DecidableEq R]
    (n : Nat) (p : Polynomial R) (omega : R) : List R :=
  if n ≤ 1 then
    [p.coeff 0]
  else
    let n2 := n / 2
    let B := fftCoeffs n2 (evenTerms p) (omega ^ 2)
    let C := fftCoeffs n2 (oddTerms p) (omega ^ 2)
    (List.range n2).flatMap fun k =>
      let wk := omega ^ k
      let bk := getCoeff B k
      let ck := getCoeff C k
      [bk + wk * ck, bk - wk * ck]

/-- Build a polynomial from sample values `b₀, …, b_{n-1}`. -/
noncomputable def polynomialize {R : Type*} [CommRing R] [DecidableEq R]
    (samples : List R) : Polynomial R :=
  (Finset.range samples.length).sum fun i =>
    C (samples.getD i 0) * X ^ i

/-- Pointwise scalar multiply on a list. -/
def scalarVector {R : Type*} [CommRing R] (vals : List R) (c : R) : List R :=
  vals.map (· * c)

/-- Fast Fourier interpolation (report §3.3.2 `FFI`). -/
noncomputable def ffi {R : Type*} [Field R] [DecidableEq R]
    (n : Nat) (samples : List R) (omega : R) : Polynomial R :=
  let bx := polynomialize samples
  let invRoot := omega⁻¹
  let Cvals := fftCoeffs n bx invRoot
  polynomialize (scalarVector Cvals (n : R)⁻¹)

end Icon2lean
