/-
Copyright (c) 2026 Catskills Research Company. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Lars Warren Ericson, Catskills Research Company
-/

import Icon2lean.Euclidean

namespace Icon2lean

/-- Kernel `Int.gcd` (natural-valued, for report-style printouts). -/
def gcdInt (a b : Int) : Nat :=
  Int.gcd a b

end Icon2lean
