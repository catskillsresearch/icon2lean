#!/bin/sh
# Run EUCLID tests: icon on code.icn + tests.icn (no .u1 bytecode).
set -e
cd "$(dirname "$0")"
python3 compare_tests.py
