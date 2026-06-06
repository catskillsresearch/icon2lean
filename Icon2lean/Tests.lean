import Icon2lean.Congruence
import Icon2lean.Gcd

namespace Icon2lean.Tests

/-- Report §3.1.3: `CRA2(6, 7, 3, 9) = 48`. -/
example : cra2 6 7 3 9 = some 48 := by native_decide

/-- Report §3.1.3: `CRA([[1,3],[3,5],[0,7],[10,11]]) = 868`. -/
example : cra [(1, 3), (3, 5), (0, 7), (10, 11)] = some 868 := by native_decide

/-- Report §3.1.2: inverse of 30 mod 197 is 46. -/
example : modularInverse 30 197 = some 46 := by native_decide

/-- Bézout for a simple pair. -/
example : euclidInt 84 54 = (6, 2, -3) := by native_decide

end Icon2lean.Tests
