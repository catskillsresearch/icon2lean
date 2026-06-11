#!/usr/bin/env python3
"""Build runnable tests.icn from Courant_Ericson_1986.md example blocks."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MD = ROOT / "Courant_Ericson_1986.md"
OUT = ROOT / "tests.icn"

HEADER = '''# EUCLID tests from Courant_Ericson_1986.md
# Expected outputs in # EXPECT: comments; verify with: python3 compare_tests.py
link "code"

global timer

procedure settime()
  timer := &time
end

procedure showtime()
  pr{"[", &time - timer, " msecs]"}
end

'''

FOOTER = '''
procedure main()
  set_base(10, 1)
  test_base_B_add()
  test_base_B_sub()
  test_base_B_mul()
  test_base_B_div()
  test_Z_ops()
  test_CRA()
  # test_MOD_RS()  # report example; ~220s on 1986 hardware — run manually
end
'''

# Hand-translated runnable tests (fancy notation kept as pr{...} control calls).
TESTS = '''
# --- test_base_B_add (md ~533) ---
# EXPECT: 1 #8# + 7 7 7 #8# = 1 0 0 0 #8#
procedure test_base_B_add()
  local x, y
  set_base(8, 1)
  x := base_B(8, [1]); y := base_B(8, [7, 7, 7])
  pr{x, " + ", y, " = ", plus_base_B(x, y)}
end

# --- test_base_B_sub (md ~591) ---
# EXPECT: 1 0 0 5 6 3 #10# - 5 3 3 5 #10# = 9 5 2 2 8 #10#
# EXPECT: 2 1 2 #10# - 9 9 #10# = 1 1 3 #10#
# EXPECT: 2 1 2 #10# - 1 9 9 #10# = 1 3 #10#
procedure test_base_B_sub()
  local x, y
  set_base(10, 1)
  x := base_B(10, [1,0,0,5,6,3]); y := base_B(10, [5,3,3,5])
  pr{x, " - ", y, " = ", ominus_base_B(x,y)}
  x := base_B(10,[2,1,2]); y := base_B(10, [9,9])
  pr{x, " - ", y, " = ", ominus_base_B(x, y)}
  y := base_B(10, [1,9,9])
  pr{x, " - ", y, " = ", ominus_base_B(x, y)}
end

# --- test_base_B_mul (md ~674) ---
# EXPECT: 2 8 1 0 7 3 2 4 #10# * 7 5 6 2 5 #10# = 2 1 2 5 6 1 6 3 7 7 5 0 0 #10#
# EXPECT: 7 4 7 8 #10# * 4 6 2 5 #10# = 3 4 5 8 5 7 5 0 #10#
procedure test_base_B_mul()
  local x, y
  set_base(10, 1)
  x := k_base_B(28107324); y := k_base_B(75625)
  pr{x, " * ", y, " = ", times_base_B(x,y)}
  x := k_base_B(7478); y := k_base_B(4625)
  pr{x, " * ", y, " = ", times_base_B(x, y)}
end

# --- test_base_B_div (md ~856) ---
# EXPECT: 1 0 #10# / 1 #10# = 1 0 #10#
# EXPECT: 4 #10# / 2 #10# = 2 #10#
# EXPECT: 2 7 #10# / 9 #10# = 3 #10#
# EXPECT: 4 2 #10# / 2 #10# = 2 1 #10#
# EXPECT: 9 0 #10# / 1 #10# = 9 0 #10#
# EXPECT: 1 8 8 1 7 5 #10# / 3 2 5 #10# = 5 7 9 #10#
# EXPECT: 1 8 8 1 7 5 #10# / 5 7 9 #10# = 3 2 5 #10#
# EXPECT: 1 8 8 1 7 5 #10# / 5 8 0 #10# = 3 2 4 #10#
# EXPECT: 1 8 8 1 7 5 #10# / 5 7 8 #10# = 3 2 5 #10#
# EXPECT: 1 2 1 9 0 3 #10# / 5 3 3 5 #10# = 2 2 #10#
# EXPECT: 2 1 2 #10# / 9 9 #10# = 2 #10#
# EXPECT: 1 1 5 6 6 8 #10# / 7 5 6 2 5 #10# = 1 #10#
procedure test_base_B_div()
  local xy, x, y
  set_base(10, 1)
  every xy := ![[10, 1], [4,2], [27, 9], [42,2], [90,1],
    [188175, 325], [188175, 579], [188175, 580],
    [188175, 578], [121903, 5335],
    [212, 99], [115668, 75625]] do {
    x := k_base_B(xy[1]); y := k_base_B(xy[2])
    pr{x, " / ", y, " = ", div_base_B(x, y)}
  }
end

# --- test_Z_ops (md ~1022) ---
# EXPECT: 1z + (-999z) = (-998z)
# EXPECT: -212z = (-212z)
# EXPECT: -(-99z) = 99z
# EXPECT: 10z / 1z = 10z
# EXPECT: 121903z / 5335z = 22z
# EXPECT: 115668z / 75625z = 1z
# EXPECT: 121903z mod 5335z = 4533z
procedure test_Z_ops()
  local x, y, xy
  set_base(10000, 4)
  x := k_Z(1); y := k_Z(-999)
  pr{x, " + ", y, " = ", plus_Z(x, y)}
  x := k_Z(212); y := k_Z(-99)
  pr{"-", x, " = ", minus_Z(x)}
  pr{"-", y, " = ", minus_Z(y)}
  every xy := ![[10, 1], [121903, 5335], [115668, 75625]] do {
    x := k_Z(xy[1]); y := k_Z(xy[2])
    pr{x, " / ", y, " = ", div_Z(x, y)}
  }
  x := k_Z(121903); y := k_Z(5335)
  pr{x, " mod ", y, " = ", mod_Z(x, y)}
end

# --- test_Q_poly (md ~1661) ---
procedure test_Q_poly()
  local ax, bx, fx, gx
  set_base(10000, 4)
  pr{"Q: 0 = ", zero_poly(poly([term(Q(zero_integer(0), one_integer(0)), 0)]))}
  pr{"QZ: 0 = ", zero_poly(poly([term(k_Z_Qx(-2, 0))]))}
  ax := poly([term(Q(-2,1), 0), term(Q(1,1), 3)])
  bx := poly([term(Q(-3,1), 0), term(Q(2,1), 3)])
  fx := poly([k_Z_Qx(-2, 0), k_Z_Qx(1,3)])
  gx := poly([k_Z_Qx(-3, 0), k_Z_Qx(2,3)])
  pr{"Q: (", ax, ") + (", bx, ") = ", plus_poly(ax, bx)}
  pr{"QZ: (", fx, ") + (", gx, ") = ", plus_poly(fx, gx)}
  pr{"Q: - (", ax, ") = ", minus_poly(ax)}
  pr{"QZ: - (", fx, ") = ", minus_poly(fx)}
  ax := poly([term(Q(-2,1), 0), term(Q(1,1), 3)])
  bx := poly([term(Q(-3,1), 0), term(Q(2,1), 3)])
  fx := poly([k_Z_Qx(-2, 0), k_Z_Qx(1,3)])
  gx := poly([k_Z_Qx(-3, 0), k_Z_Qx(2,3)])
  pr{"Q: (", ax, ") * (", bx, ") = ", times_poly(ax, bx)}
  pr{"QZ: (", fx, ") * (", gx, ") = ", times_poly(fx, gx)}
end

# --- test_CRA (md ~2442) ---
# EXPECT: 868
procedure test_CRA()
  local a, b, ux, a_congruences, b_congruences
  pr{CRA([[1, 3], [3, 5], [0, 7], [10, 11]])}
  a_congruences := [[1, 3], [0, 7], [2, 4], [3, 5]]
  b_congruences := [[0, 3], [1, 7], [3, 4], [3, 5]]
  a := CRA(a_congruences)
  b := CRA(b_congruences)
  ux := poly([term(b, 0), term(a, 1)])
  pr{"u(x) = ", ux}
end

# --- test_MOD_RS (md ~2555) ---
procedure test_MOD_RS()
  local ax, bx
  set_base(10000, 4)
  settime()
  ax := poly([k_Z_Qx(2, 0), k_Z_Qx(-1, 1), k_Z_Qx(3, 2), k_Z_Qx(2, 4), k_Z_Qx(1, 5)])
  bx := poly([k_Z_Qx(2, 0), k_Z_Qx(-1, 1), k_Z_Qx(3, 3)])
  pr{"QZ[x]: MOD_RS(", ax, ", ", bx, ") = ", MOD_RS(ax, bx)}
  showtime()
end
'''


def main() -> None:
    OUT.write_text(HEADER + TESTS + FOOTER)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
