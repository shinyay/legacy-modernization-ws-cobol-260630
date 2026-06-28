#!/usr/bin/env bash
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$DIR/../bin/aud-write-test"
export COB_LIBRARY_PATH="$DIR/../bin:/workspace/shared/util/shared-log/bin"
export LD_PRELOAD=/usr/local/lib/libocesql.so
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -tA"

PASS=0; FAIL=0; declare -a FAILS=()
chk(){ if [ "$2" = "$3" ]; then echo "  [PASS] $1 = $3"; PASS=$((PASS+1));
  else echo "  [FAIL] $1 exp=$2 act=$3"; FAIL=$((FAIL+1)); FAILS+=("$1"); fi; }

echo "=== AUD-WRITE idempotency-key row-count test (#2) ==="

$PSQL -c "DELETE FROM audit_log WHERE event_key IN ('TXN_POSTED:AWIDEMK1','TXN_POSTED:AWIDEMK2')"
$PSQL -c "DELETE FROM audit_log WHERE event_key IS NULL AND subsystem='awtest' AND action='blankctl' AND business_date='2026-06-11'"
BLANK_BEFORE=$($PSQL -c "SELECT count(*) FROM audit_log WHERE event_key IS NULL AND subsystem='awtest' AND business_date='2026-06-11'")

"$BIN" > /tmp/aud-idem.out 2>&1 || true

K1=$($PSQL -c "SELECT count(*) FROM audit_log WHERE event_key='TXN_POSTED:AWIDEMK1'")
K2=$($PSQL -c "SELECT count(*) FROM audit_log WHERE event_key='TXN_POSTED:AWIDEMK2'")
echo "  [info] K1(dup keyed)=$K1  K2(distinct keyed)=$K2  driver Total=$(grep -aoE 'Total: [0-9]+ \| PASS: [0-9]+ \| FAIL: [0-9]+' /tmp/aud-idem.out | tail -1)"
chk "duplicate keyed event => exactly 1 row" 1 "$K1"
chk "distinct keyed event => exactly 1 row" 1 "$K2"
grep -aqE 'FAIL: 000' /tmp/aud-idem.out \
  && { echo "  [PASS] driver all rc assertions pass (dup CALL rc=0)"; PASS=$((PASS+1)); } \
  || { echo "  [FAIL] driver had rc failures"; FAIL=$((FAIL+1)); FAILS+=("driver"); }

$PSQL -c "DELETE FROM audit_log WHERE event_key IS NULL AND subsystem='awtest' AND action='blankctl'" >/dev/null
$PSQL -c "INSERT INTO audit_log (business_date,system_ts,subsystem,action,actor,target_type,target_id,payload_json,severity,schema_version) VALUES ('2026-06-11',NOW(),'awtest','blankctl','SYSTEM','TEST','c','{}','I','1.0'),('2026-06-11',NOW(),'awtest','blankctl','SYSTEM','TEST','c','{}','I','1.0')" >/dev/null
BLANKDUP=$($PSQL -c "SELECT count(*) FROM audit_log WHERE event_key IS NULL AND subsystem='awtest' AND action='blankctl'")
chk "blank event_key NOT deduped (2 rows)" 2 "$BLANKDUP"
$PSQL -c "DELETE FROM audit_log WHERE subsystem='awtest' AND action='blankctl'" >/dev/null

echo "[verify] PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -gt 0 ]; then echo "FAILED: ${FAILS[*]}"; exit 1; fi
echo "=== AUD-WRITE idempotency test COMPLETE ==="
