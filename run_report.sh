#!/usr/bin/env bash
# Icon tests.icn stdout only (parallel to run_lean_report.sh).
set -euo pipefail
cd "$(dirname "$0")"
python3 - <<'PY'
from compare_tests import bundle_icon, run_icon
from pathlib import Path
bundle = bundle_icon()
rc, stdout, stderr = run_icon(bundle)
if rc == -1:
    raise SystemExit("icon interpreter not found")
if stderr:
    import sys
    print(stderr, file=sys.stderr)
print(stdout, end="")
PY
