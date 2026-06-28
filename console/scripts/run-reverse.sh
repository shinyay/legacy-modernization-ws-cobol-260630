#!/usr/bin/env bash
set -u

DIR="${1:?revs workdir required}"

if [ "${CONSOLE_ALLOW_WRITE:-}" != "YES" ]; then
  echo "write gate disabled (set CONSOLE_ALLOW_WRITE=YES)" >&2
  exit 3
fi

REQ="$DIR/request.txt"
RES="$DIR/result.txt"
LOG="$DIR/run.log"

if [ ! -f "$REQ" ]; then
  echo "no request file: $REQ" >&2
  exit 2
fi

WS=/workspace
DRIVER="$WS/console/bin/con-reverse"
if [ ! -x "$DRIVER" ]; then
  echo "driver not built: $DRIVER" >&2
  exit 2
fi

export PGHOST="${PGHOST:-postgres}" PGUSER="${PGUSER:-cobol}"
export PGPASSWORD="${PGPASSWORD:-cobol}" PGDATABASE="${PGDATABASE:-banking}"
export LD_PRELOAD="${LD_PRELOAD:-/usr/local/lib/libocesql.so}"
export COB_LIBRARY_PATH=\
$WS/subsystems/12-txnpost/bin:\
$WS/subsystems/01-calendar/bin:\
$WS/subsystems/08-account/bin:\
$WS/shared/util/aud-write/bin:\
$WS/shared/util/shared-log/bin
export CONSOLE_REVS_DIR="$DIR"

rm -f "$RES"

timeout 30 "$DRIVER" < /dev/null > "$LOG" 2>&1
rc=$?

if [ "$rc" = 124 ]; then
  echo "con-reverse timed out" >&2
  exit 4
fi

if [ ! -f "$RES" ]; then
  echo "no result file after run (driver rc=$rc)" >&2
  [ "$rc" -ne 0 ] && exit 4
  exit 5
fi

exit 0
