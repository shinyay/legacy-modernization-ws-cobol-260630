#!/usr/bin/env bash
set -u

DIR="${1:?post workdir required}"

if [ "${CONSOLE_ALLOW_WRITE:-}" != "YES" ]; then
  echo "write gate disabled (set CONSOLE_ALLOW_WRITE=YES)" >&2
  exit 3
fi

WS=/workspace
GEN="$WS/console/bin/con-post-gen"
STAGE="$WS/console/scripts/run-stage.sh"
REQ="$DIR/request.txt"
META="$DIR/post-meta.txt"
RES="$DIR/result.txt"

[ -f "$REQ" ] || { echo "no request file: $REQ" >&2; exit 2; }
[ -x "$GEN" ] || { echo "generator not built: $GEN" >&2; exit 2; }

export PGHOST="${PGHOST:-postgres}" PGUSER="${PGUSER:-cobol}"
export PGPASSWORD="${PGPASSWORD:-cobol}" PGDATABASE="${PGDATABASE:-banking}"
export LD_PRELOAD="${LD_PRELOAD:-/usr/local/lib/libocesql.so}"
export COB_LIBRARY_PATH=\
$WS/subsystems/01-calendar/bin:\
$WS/subsystems/08-account/bin:\
$WS/shared/util/aud-write/bin:\
$WS/shared/util/shared-log/bin
export CONSOLE_POST_DIR="$DIR"
PSQL="psql -h $PGHOST -U $PGUSER -d $PGDATABASE -tA"

mkdir -p "$DIR"
rm -f "$DIR"/txn-*.dat "$DIR"/*.ckpt "$DIR"/tmp/* "$RES" "$META"

"$GEN" < /dev/null > "$DIR/gen.log" 2>&1
genrc=$?
[ -f "$META" ] || { echo "no meta from generator (rc=$genrc)" >&2; exit 2; }
IFS='|' read -r BATCH BDATE COUNT GSTATUS < "$META"

if [ "$GSTATUS" = "ALREADY" ]; then
  echo "ALREADY|0|0|$BATCH|$BDATE|already posted for $BDATE" > "$RES"
  exit 9
fi
if [ "$GSTATUS" != "OK" ]; then
  echo "ERR|0|0|$BATCH|$BDATE|generator error" > "$RES"
  exit 2
fi

run_stage() { bash "$STAGE" "$1" "$DIR" "$BATCH" "$BDATE"; }

run_stage s10 || { echo "ERR|0|0|$BATCH|$BDATE|s10 failed" > "$RES"; exit 4; }

jget() { # file key -> integer (strips zero-padding); 0 if absent
  local v
  v=$(grep -aoE "\"$2\":[0-9]+" "$1" 2>/dev/null | head -1 | grep -aoE '[0-9]+')
  echo $(( 10#${v:-0} ))
}
COUNT=$(( 10#${COUNT:-0} ))
VALIDATED=$(jget "$DIR/stage-s10.log" validated)
S10REJ=$(jget "$DIR/stage-s10.log" rejected)
REASONS=$(grep -aoE 'E[0-9]{3}' "$DIR/txn-error.dat" 2>/dev/null | sort -u | tr '\n' ' ')

if [ "$VALIDATED" = "0" ]; then
  echo "ALLREJECT|0|$COUNT|$BATCH|$BDATE|${REASONS:-rejected}" > "$RES"
  exit 0
fi

run_stage s11 || { echo "ERR|0|0|$BATCH|$BDATE|s11 failed" > "$RES"; exit 4; }
run_stage s12 || { echo "ERR|0|0|$BATCH|$BDATE|s12 failed" > "$RES"; exit 4; }

POSTED=$(jget "$DIR/stage-s12.log" records_posted)
S12REJ=$(jget "$DIR/stage-s12.log" hard_rejected)
DEFER=$(jget "$DIR/stage-s12.log" recon_defer)
REJECTED=$(( S10REJ + S12REJ ))
REASONS=$(grep -aoE 'E[0-9]{3}' "$DIR/txn-error.dat" 2>/dev/null | sort -u | tr '\n' ' ')

STATUS=OK
if [ "$POSTED" -ne "$COUNT" ] || [ "$REJECTED" -ne 0 ] || [ "$DEFER" -ne 0 ]; then
  STATUS=PARTIAL
fi
echo "$STATUS|$POSTED|$REJECTED|$BATCH|$BDATE|${REASONS:-}" > "$RES"
exit 0
