#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WS=/workspace

export PGHOST="${PGHOST:-postgres}" PGUSER="${PGUSER:-cobol}"
export PGPASSWORD="${PGPASSWORD:-cobol}" PGDATABASE="${PGDATABASE:-banking}"
export LD_PRELOAD="${LD_PRELOAD:-/usr/local/lib/libocesql.so}"
export COB_LIBRARY_PATH="\
$WS/subsystems/12-txnpost/bin:\
$WS/subsystems/01-calendar/bin:\
$WS/subsystems/02-branch/bin:\
$WS/subsystems/05-product/bin:\
$WS/subsystems/08-account/bin:\
$WS/shared/util/aud-write/bin:\
$WS/shared/util/shared-log/bin"
PSQL="psql -h $PGHOST -U $PGUSER -d $PGDATABASE -tA"
DRIVER="$WS/tests/e2e/bin/e2e-driver"

PASS=0; FAIL=0; declare -a FAILS=()
check() { # label expected actual
  if [ "$2" = "$3" ]; then
    echo "  [PASS] $1 = $3"; PASS=$((PASS+1))
  else
    echo "  [FAIL] $1 expected=$2 actual=$3"; FAIL=$((FAIL+1)); FAILS+=("$1")
  fi
}
num() { echo $((10#${1:-0})); }

seed_orig() { # resets PG + posts 90 txns; echoes a cat-10 PT orig txn_id
  bash "$SCRIPT_DIR/e2e-run.sh" smoke > /tmp/rev-seed.log 2>&1 || true
  $PSQL -c "SELECT txn_id FROM transactions WHERE category='10' AND status='PT' ORDER BY txn_id LIMIT 1"
}

run_reverse() { # ORIG FAULT_N MAX  -> sets RV_STATUS RV_NEWID RV_RETRIES RV_OUTCOME
  local out
  out=$(TXPOST_FAULT_CONFLICT_N="$2" TXPOST_MAX_RETRIES="$3" TXPOST_BACKOFF_MS=0 \
        "$DRIVER" reverse "$1" "c1b reverse test" "op-c1b" 2>/dev/null)
  RV_STATUS=$(echo "$out" | sed -n 's/.*"status":"\([0-9]*\)".*/\1/p')
  RV_NEWID=$(echo "$out" | sed -n 's/.*"new_rv_txn_id":"\([^"]*\)".*/\1/p' | tr -d ' ')
  RV_RETRIES=$(num "$(echo "$out" | sed -n 's/.*retries=\([0-9]*\).*/\1/p')")
  RV_OUTCOME=$(echo "$out" | sed -n 's/.*outcome=\([A-Z]*\).*/\1/p')
}

rv_count() { $PSQL -c "SELECT count(*) FROM transactions WHERE reversal_of='$1' AND status='RV'"; }

echo "=== C-1b SERIALIZABLE retry FSM (REVS) test ==="

echo "[A] retry-and-succeed: TXPOST_FAULT_CONFLICT_N=2 TXPOST_MAX_RETRIES=5"
ORIG=$(seed_orig)
run_reverse "$ORIG" 2 5
RVN=$(rv_count "$ORIG")
RVTXN=$($PSQL -c "SELECT txn_id FROM transactions WHERE reversal_of='$ORIG' AND status='RV'")
POSN=$($PSQL -c "SELECT count(*) FROM postings WHERE txn_id='$RVTXN'")
DR=$($PSQL -c "SELECT COALESCE(SUM(debit_jpy),0) FROM postings WHERE txn_id='$RVTXN'")
CR=$($PSQL -c "SELECT COALESCE(SUM(credit_jpy),0) FROM postings WHERE txn_id='$RVTXN'")
echo "  [info] A orig=$ORIG status=$RV_STATUS newid=$RV_NEWID retries=$RV_RETRIES" \
     "outcome=$RV_OUTCOME RVrows=$RVN postings=$POSN DR=$DR CR=$CR"
check "A reversal status 00"        00  "$RV_STATUS"
check "A ser_retries (=2)"           2  "$RV_RETRIES"
check "A outcome OK"                OK  "$RV_OUTCOME"
check "A exactly one RV row"         1  "$RVN"
check "A RV posting pair"            2  "$POSN"
check "A RV DR=CR balanced"      "$DR"  "$CR"
[ -n "$RV_NEWID" ] && { echo "  [PASS] A new RV id present = $RV_NEWID"; PASS=$((PASS+1)); } \
  || { echo "  [FAIL] A new RV id empty"; FAIL=$((FAIL+1)); FAILS+=("A newid"); }

echo "[B] exhaustion: TXPOST_FAULT_CONFLICT_N=10 TXPOST_MAX_RETRIES=2"
ORIG=$(seed_orig)
DRACCT=$($PSQL -c "SELECT account_number FROM transactions WHERE txn_id='$ORIG'")
BAL_BEFORE=$($PSQL -c "SELECT balance_jpy FROM balances WHERE account_number='$DRACCT'")
run_reverse "$ORIG" 10 2
RVN=$(rv_count "$ORIG")
BAL_AFTER=$($PSQL -c "SELECT balance_jpy FROM balances WHERE account_number='$DRACCT'")
echo "  [info] B orig=$ORIG status=$RV_STATUS newid=[$RV_NEWID] outcome=$RV_OUTCOME" \
     "RVrows=$RVN bal_before=$BAL_BEFORE bal_after=$BAL_AFTER"
check "B reversal status 12 (IO-FAIL)"  12  "$RV_STATUS"
check "B outcome EXHAUST"          EXHAUST  "$RV_OUTCOME"
check "B no RV row (no partial)"         0  "$RVN"
check "B balance unchanged"  "$BAL_BEFORE"  "$BAL_AFTER"
[ -z "$RV_NEWID" ] && { echo "  [PASS] B no RV id returned"; PASS=$((PASS+1)); } \
  || { echo "  [FAIL] B stale RV id returned = $RV_NEWID"; FAIL=$((FAIL+1)); FAILS+=("B stale id"); }

conc_reverse() { # ORIG OUTFILE  (real serialization, generous retry budget)
  TXPOST_MAX_RETRIES=50 TXPOST_BACKOFF_MS=5 \
    "$DRIVER" reverse "$1" "c1b conc reverse" "op-c1b" > "$2" 2>/dev/null
}
parse_status() { sed -n 's/.*"status":"\([0-9]*\)".*/\1/p' "$1"; }

echo "[C] concurrent reversals of two DIFFERENT origs (RV-id contention)"
seed_orig > /dev/null
mapfile -t ORIGS < <($PSQL -c "SELECT txn_id FROM transactions WHERE category='10' AND status='PT' ORDER BY txn_id LIMIT 2")
OC1="${ORIGS[0]}"; OC2="${ORIGS[1]}"
conc_reverse "$OC1" /tmp/revC1.out &
PC1=$!
conc_reverse "$OC2" /tmp/revC2.out &
PC2=$!
wait "$PC1"; wait "$PC2"
SC1=$(parse_status /tmp/revC1.out); SC2=$(parse_status /tmp/revC2.out)
RVC1=$(rv_count "$OC1"); RVC2=$(rv_count "$OC2")
RVID1=$($PSQL -c "SELECT txn_id FROM transactions WHERE reversal_of='$OC1' AND status='RV'")
RVID2=$($PSQL -c "SELECT txn_id FROM transactions WHERE reversal_of='$OC2' AND status='RV'")
echo "  [info] C orig1=$OC1 st=$SC1 rv=$RVID1 | orig2=$OC2 st=$SC2 rv=$RVID2"
check "C orig1 reversal status 00"  00  "$SC1"
check "C orig2 reversal status 00"  00  "$SC2"
check "C orig1 one RV row"           1  "$RVC1"
check "C orig2 one RV row"           1  "$RVC2"
[ -n "$RVID1" ] && [ "$RVID1" != "$RVID2" ] \
  && { echo "  [PASS] C distinct RV ids (re-alloc worked)"; PASS=$((PASS+1)); } \
  || { echo "  [FAIL] C RV ids not distinct ($RVID1 / $RVID2)"; FAIL=$((FAIL+1)); FAILS+=("C ids"); }

echo "[D] concurrent reversals of the SAME orig (no double-reversal)"
ORIG=$(seed_orig)
conc_reverse "$ORIG" /tmp/revD1.out &
PD1=$!
conc_reverse "$ORIG" /tmp/revD2.out &
PD2=$!
wait "$PD1"; wait "$PD2"
SD1=$(parse_status /tmp/revD1.out); SD2=$(parse_status /tmp/revD2.out)
RVD=$(rv_count "$ORIG")
OKN=0; INVN=0
for s in "$SD1" "$SD2"; do
  [ "$s" = "00" ] && OKN=$((OKN+1))
  [ "$s" = "08" ] && INVN=$((INVN+1))
done
echo "  [info] D orig=$ORIG st1=$SD1 st2=$SD2 OK=$OKN INVALID=$INVN RVrows=$RVD"
check "D exactly one OK"          1  "$OKN"
check "D exactly one INVALID(08)" 1  "$INVN"
check "D exactly one RV row"      1  "$RVD"

echo "[verify] PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo "[verify] FAILED: ${FAILS[*]}"
  exit 1
fi
echo "=== C-1b reverse-retry test COMPLETE ==="
