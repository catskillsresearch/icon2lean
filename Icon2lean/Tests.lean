import Icon2lean.Congruence
import Icon2lean.Diophantine
import Icon2lean.Gcd

set_option linter.style.nativeDecide false

/-!
Report §3.1 worked examples — each `example` matches a value printed in
*Courant_Ericson_1986* (NYU CS TR #232). Polynomial examples (§3.2) are
listed in `icon2lean.md`; run them interactively once `Icon2lean/Polynomial.lean`
is imported.
-/

open Icon2lean

namespace Icon2lean.Tests

section Gcd

/-- Report §3.1.1 extended gcd table (machine integers). -/
example : euclidInt 84 54 = (6, 2, -3) := by native_decide

end Gcd

section Congruence

/-- Report §3.1.3: `CRA1(7, 1432, 5317) = 4762`. -/
example : cra1 7 1432 5317 = some 4762 := by native_decide

/-- Report §3.1.3: `CRA1(863, 880, 2151) = 173`. -/
example : cra1 863 880 2151 = some 173 := by native_decide

/-- Report §3.1.3: `CRA1(589, 509, 817)` has no solution. -/
example : cra1 589 509 817 = none := by native_decide

/-- Report §3.1.3: `CRA2(6, 7, 3, 9) = 48`. -/
example : cra2 6 7 3 9 = some 48 := by native_decide

/-- Report §3.1.3 (Lipson p. 258): `CRA([[1,3],[3,5],[0,7],[10,11]]) = 868`. -/
example : cra [(1, 3), (3, 5), (0, 7), (10, 11)] = some 868 := by native_decide

end Congruence

section Diophantine

/-- Report §3.1.4: particular solution `(1, -2)` for `84x + 54y = -24`. -/
example : (diophantine 84 54 (-24)).map (fun s => (s.x0, s.y0)) = some (1, -2) := by
  native_decide

/-- Report §3.1.4: particular solution `(13, 163)` for `999x - 49y = 5000`. -/
example : (diophantine 999 (-49) 5000).map (fun s => (s.x0, s.y0)) = some (13, 163) := by
  native_decide

/-- Report §3.1.4: particular solution `(-11, 6)` for `247x + 589y = 817`. -/
example : (diophantine 247 589 817).map (fun s => (s.x0, s.y0)) = some (-11, 6) := by
  native_decide

end Diophantine

end Icon2lean.Tests
