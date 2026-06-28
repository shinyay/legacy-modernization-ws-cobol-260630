#!/usr/bin/env bash
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$DIR/../bin/aud-drain-main"
export COB_LIBRARY_PATH="$DIR/../bin:/workspace/shared/util/aud-write/bin:/workspace/shared/util/shared-log/bin"
export LD_PRELOAD=/usr/local/lib/libocesql.so
export PGHOST="${PGHOST:-postgres}"
export PGUSER="${PGUSER:-cobol}"
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h $PGHOST -U $PGUSER -d ${PGDATABASE:-banking} -tA"

PASS=0; FAIL=0; declare -a FAILS=()
chk(){ if [ "$2" = "$3" ]; then echo "  [PASS] $1 = $3"; PASS=$((PASS+1));
  else echo "  [FAIL] $1 exp=$2 act=$3"; FAIL=$((FAIL+1)); FAILS+=("$1"); fi; }

ACT="ADRNT"
EK="ADRNT"   # event_key prefix
run_drain(){ "$BIN" "$@" >/tmp/aud-drain.out 2>&1; echo $?; }
seed(){ # seed(bdate, target_id) -> one keyed intent
  $PSQL -c "INSERT INTO audit_outbox (business_date,subsystem,action,actor,target_type,target_id,payload_json,severity,event_key) VALUES ('$1','12-txnpost','$ACT','SYSTEM','TXN','$2','{\"t\":\"$2\"}','I','$EK:$2')" >/dev/null; }
aud_cnt(){ $PSQL -c "SELECT count(*) FROM audit_log WHERE event_key LIKE '$EK:%'"; }
box_cnt(){ $PSQL -c "SELECT count(*) FROM audit_outbox WHERE TRIM(action)='$ACT'"; }
clean(){ $PSQL -c "DELETE FROM audit_outbox WHERE TRIM(action)='$ACT'" >/dev/null
         $PSQL -c "DELETE FROM audit_log WHERE event_key LIKE '$EK:%'" >/dev/null; }

echo "=== AUD-DRAIN transactional-outbox drainer test (#2 / Option B) ==="
clean

seed 2026-06-12 A1; seed 2026-06-12 A2; seed 2026-06-12 A3
RC=$(run_drain)
chk "TC1 drain-all exit=0" 0 "$RC"
chk "TC1 audit_log has 3 relayed" 3 "$(aud_cnt)"
chk "TC1 outbox emptied" 0 "$(box_cnt)"
grep -aq "drained=000000003" /tmp/aud-drain.out \
  && { echo "  [PASS] TC1 reported drained=3"; PASS=$((PASS+1)); } \
  || { echo "  [FAIL] TC1 drained count"; FAIL=$((FAIL+1)); FAILS+=("TC1-count"); }

RC=$(run_drain)
chk "TC2 re-drain exit=0" 0 "$RC"
chk "TC2 audit_log unchanged (3)" 3 "$(aud_cnt)"
grep -aq "drained=000000000" /tmp/aud-drain.out \
  && { echo "  [PASS] TC2 reported drained=0"; PASS=$((PASS+1)); } \
  || { echo "  [FAIL] TC2 drained count"; FAIL=$((FAIL+1)); FAILS+=("TC2-count"); }

seed 2026-06-12 A1            # event_key ADRNT:A1 already in audit_log (TC1)
RC=$(run_drain)
chk "TC3 idempotent exit=0" 0 "$RC"
chk "TC3 audit_log still 3 (no dup)" 3 "$(aud_cnt)"
chk "TC3 outbox emptied" 0 "$(box_cnt)"

clean
seed 2026-06-12 B1; seed 2026-06-13 B2
RC=$(run_drain 20260612)
chk "TC4 filtered exit=0" 0 "$RC"
chk "TC4 only 1 relayed (06-12)" 1 "$(aud_cnt)"
chk "TC4 06-13 row left in outbox" 1 "$(box_cnt)"
LEFT=$($PSQL -c "SELECT business_date FROM audit_outbox WHERE TRIM(action)='$ACT'")
chk "TC4 remaining row is 2026-06-13" "2026-06-13" "$LEFT"

clean
echo "[verify] PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -gt 0 ]; then echo "FAILED: ${FAILS[*]}"; exit 1; fi
echo "=== AUD-DRAIN drainer test COMPLETE ($PASS/$PASS) ==="
