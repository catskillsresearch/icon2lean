#!/usr/bin/env bash
# Print all #eval results from Icon2lean.Tests (parity with tests.icn §3 benchmarks).
set -euo pipefail
cd "$(dirname "$0")"
lake build Icon2lean.Tests 2>&1 | grep "^info: Icon2lean/Tests"
