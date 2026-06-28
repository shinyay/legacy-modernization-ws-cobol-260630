#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."

scripts/gen-seed/gen-calendar-seed.py
scripts/gen-seed/gen-branches-seed.py
scripts/gen-seed/gen-products-seed.py
scripts/gen-seed/gen-customers-seed.py
scripts/gen-seed/gen-interestrates-seed.py
scripts/gen-seed/gen-feeschedules-seed.py

echo
echo "All 6 seeds generated. Total:"
find subsystems -name "*.dat" -path "*/data/*" -exec wc -c {} + | tail -10
