#!/usr/bin/env bash
set -euo pipefail

WS="${WS:-/workspace}"
export PGHOST="${PGHOST:-postgres}" PGUSER="${PGUSER:-cobol}"
export PGPASSWORD="${PGPASSWORD:-cobol}" PGDATABASE="${PGDATABASE:-banking}"

if [ "${1:-}" = "--clear" ]; then
  psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -q \
    -c "DELETE FROM audit_log WHERE action LIKE 'DEMO\_%'"
  echo "[seed-audit-demo] cleared DEMO_* audit rows"
  exit 0
fi

BDATE="${1:-20260612}"
case "$BDATE" in
  [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) : ;;
  *) echo "invalid business date '$BDATE' (want YYYYMMDD)" >&2; exit 2 ;;
esac

if ! ls "$WS"/shared/util/aud-write/bin/*.so >/dev/null 2>&1; then
  echo "AUD-WRITE not built — run:  cd /workspace && make setup" >&2
  exit 1
fi

export LD_PRELOAD="${LD_PRELOAD:-/usr/local/lib/libocesql.so}"
export COB_LIBRARY_PATH="$WS/shared/util/aud-write/bin:$WS/shared/util/shared-log/bin"
export DEMO_AUDIT_BDATE="$BDATE"
exec "$WS/console/bin/con-audit-demo"
