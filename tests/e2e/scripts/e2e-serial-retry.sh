#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WS=/workspace
RESULTS=/tmp/e2e/results
BDATE_PG=2026-06-12

export PGHOST="${PGHOST:-postgres}" PGUSER="${PGUSER:-cobol}"
export PGPASSWORD="${PGPASSWORD:-cobol}" PGDATABASE="${PGDATABASE:-banking}"
PSQL="psql -h $PGHOST -U $PGUSER -d $PGDATABASE -tA"

PASS=0; FAIL=0; declare -a FAILS=()
check() { # label expected actual
  if [ "$2" = "$3" ]; then
    echo "  [PASS] $1 = $3"; PASS=$((PASS+1))
  else
    echo "  [FAIL] $1 expected=$2 actual=$3"; FAIL=$((FAIL+1)); FAILS+=("$1")
  fi
}

num() { echo $((10#${1:-0})); }  # strip leading zeros safely

run_pipeline() { # FAULT_N MAX_RETRIES
  export TXPOST_FAULT_CONFLICT_N="$1"
  export TXPOST_MAX_RETRIES="$2"
  export TXPOST_BACKOFF_MS=0
  bash "$SCRIPT_DIR/e2e-run.sh" smoke > /tmp/ser-retry-run.log 2>&1 || true
  unset TXPOST_FAULT_CONFLICT_N TXPOST_MAX_RETRIES TXPOST_BACKOFF_MS
}

parse_metrics() { # sets RET ROK EXH POSTED DEFER from stage5.out
  local sm js
  sm=$(grep -a 'ser_metrics' "$RESULTS/stage5.out" | tail -1)
  RET=$(num "$(echo "$sm" | sed -n 's/.*retries=\([0-9]*\).*/\1/p')")
  ROK=$(num "$(echo "$sm" | sed -n 's/.*retry_ok=\([0-9]*\).*/\1/p')")
  EXH=$(num "$(echo "$sm" | sed -n 's/.*exhausted=\([0-9]*\).*/\1/p')")
  js=$(grep -a 'records_posted' "$RESULTS/stage5.out" | tail -1)
  POSTED=$(num "$(echo "$js" | sed -n 's/.*"records_posted":\([0-9]*\).*/\1/p')")
  DEFER=$(num "$(echo "$js" | sed -n 's/.*"recon_defer":\([0-9]*\).*/\1/p')")
}

pg_counts() { # sets TXN POS DRS CRS
  TXN=$($PSQL -c "SELECT count(*) FROM transactions WHERE business_date='$BDATE_PG'")
  POS=$($PSQL -c "SELECT count(*) FROM postings WHERE business_date='$BDATE_PG'")
  DRS=$($PSQL -c "SELECT COALESCE(SUM(debit_jpy),0) FROM postings WHERE business_date='$BDATE_PG'")
  CRS=$($PSQL -c "SELECT COALESCE(SUM(credit_jpy),0) FROM postings WHERE business_date='$BDATE_PG'")
}

echo "=== C-1 SERIALIZABLE retry FSM test ==="

echo "[A] retry-and-succeed: TXPOST_FAULT_CONFLICT_N=2 TXPOST_MAX_RETRIES=5"
run_pipeline 2 5
parse_metrics
pg_counts
echo "  [info] A ser_metrics retries=$RET retry_ok=$ROK exhausted=$EXH" \
     "posted=$POSTED recon_defer=$DEFER PG txn=$TXN pos=$POS DR=$DRS CR=$CRS"
check "A records_posted"          90  "$POSTED"
check "A ser_retries (90 x 2)"   180  "$RET"
check "A retry_succeeded"          90  "$ROK"
check "A exhausted_defer"           0  "$EXH"
check "A recon_defer"               0  "$DEFER"
check "A PG transactions"          90  "$TXN"
check "A PG postings (no dup)"    180  "$POS"
check "A DR=CR conserved"      "$DRS"  "$CRS"

echo "[B] exhaustion: TXPOST_FAULT_CONFLICT_N=10 TXPOST_MAX_RETRIES=2"
run_pipeline 10 2
parse_metrics
pg_counts
echo "  [info] B ser_metrics retries=$RET retry_ok=$ROK exhausted=$EXH" \
     "posted=$POSTED recon_defer=$DEFER PG txn=$TXN pos=$POS"
check "B records_posted (none)"     0  "$POSTED"
check "B retry_succeeded (none)"    0  "$ROK"
check "B exhausted_defer (all)"    90  "$EXH"
check "B recon_defer (all)"        90  "$DEFER"
check "B PG transactions (none)"    0  "$TXN"
check "B PG postings (no partial)"  0  "$POS"

echo "[verify] PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo "[verify] FAILED: ${FAILS[*]}"
  exit 1
fi
echo "=== C-1 serial-retry test COMPLETE ==="
