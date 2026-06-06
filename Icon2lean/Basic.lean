import Icon2lean.Types
import Icon2lean.Gcd
import Icon2lean.Congruence
import Icon2lean.Diophantine
import Icon2lean.Polynomial
import Icon2lean.Interpolation
import Icon2lean.Fft
import Icon2lean.PowerSeries

namespace Icon2lean

/-- Demo values matching the report's `kz` examples. -/
def demoZ : Int × Int × Int := (1, -999, 1 + (-999))

/-- Expected `CRA2(6, 7, 3, 9) = 48` from report §3.1.3. -/
def demoCra2 : Option Int := cra2 6 7 3 9

/-- Expected `CRA([[1,3],[3,5],[0,7],[10,11]]) = 868` from report §3.1.3. -/
def demoCra868 : Option Int :=
  cra [(1, 3), (3, 5), (0, 7), (10, 11)]

end Icon2lean
