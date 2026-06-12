#!/usr/bin/env bash
# Icon-style §3 benchmark report (parity with tests.icn labeled stdout).
set -euo pipefail
cd "$(dirname "$0")"
lake exe iconReport 2>/dev/null
