#!/usr/bin/env bash
set -u

MODE="$1"; BATCH_ID="$2"; BDATE="$3"; WORKDIR="$4"; RESULTS="$5"

export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -tA"

PASS=0; FAIL=0
declare -a FAILS=()
check() {
  local label="$1" expected="$2" actual="$3" cmp="${4:-eq}"
  case "$cmp" in
    eq)
      if [ "$expected" = "$actual" ]; then
        echo "  [PASS] $label = $actual"
        PASS=$((PASS+1))
      else
        echo "  [FAIL] $label expected=$expected actual=$actual"
        FAIL=$((FAIL+1))
        FAILS+=("$label")
      fi
      ;;
    ge)
      if [ "$actual" -ge "$expected" ] 2>/dev/null; then
        echo "  [PASS] $label >= $expected (=$actual)"
        PASS=$((PASS+1))
      else
        echo "  [FAIL] $label expected>=$expected actual=$actual"
        FAIL=$((FAIL+1))
        FAILS+=("$label")
      fi
      ;;
  esac
}

BDATE_PG=$(echo "$BDATE" | sed 's/\(....\)\(..\)\(..\)/\1-\2-\3/')

echo "[verify] mode=$MODE batch=$BATCH_ID bdate=$BDATE_PG"

[ -s "$WORKDIR/txn-decoded.dat" ] && echo "  [PASS] txn-decoded.dat exists" && PASS=$((PASS+1)) || { echo "  [FAIL] txn-decoded.dat empty"; FAIL=$((FAIL+1)); FAILS+=("decoded missing"); }
[ -s "$WORKDIR/txn-valid.dat" ]   && echo "  [PASS] txn-valid.dat exists"   && PASS=$((PASS+1)) || { echo "  [FAIL] txn-valid.dat empty";   FAIL=$((FAIL+1)); FAILS+=("valid missing"); }
[ -s "$WORKDIR/txn-sorted.dat" ]  && echo "  [PASS] txn-sorted.dat exists"  && PASS=$((PASS+1)) || { echo "  [FAIL] txn-sorted.dat empty";  FAIL=$((FAIL+1)); FAILS+=("sorted missing"); }
[ -s "$WORKDIR/txn-ready.dat" ]   && echo "  [PASS] txn-ready.dat exists"   && PASS=$((PASS+1)) || { echo "  [FAIL] txn-ready.dat empty";   FAIL=$((FAIL+1)); FAILS+=("ready missing"); }

DEC_BYTES=$(stat -c %s "$WORKDIR/txn-decoded.dat" 2>/dev/null || echo 0)
DEC_REC=$((DEC_BYTES / 600))
VAL_BYTES=$(stat -c %s "$WORKDIR/txn-valid.dat" 2>/dev/null || echo 0)
VAL_REC=$((VAL_BYTES / 600))
SOR_BYTES=$(stat -c %s "$WORKDIR/txn-sorted.dat" 2>/dev/null || echo 0)
SOR_REC=$((SOR_BYTES / 600))
RDY_BYTES=$(stat -c %s "$WORKDIR/txn-ready.dat" 2>/dev/null || echo 0)
RDY_REC=$((RDY_BYTES / 600))

echo "  [info] file rec counts: decoded=$DEC_REC valid=$VAL_REC sorted=$SOR_REC ready=$RDY_REC"

TXN_CNT=$($PSQL -c "SELECT count(*) FROM transactions WHERE business_date='$BDATE_PG'")
POS_CNT=$($PSQL -c "SELECT count(*) FROM postings WHERE business_date='$BDATE_PG'")
AUD_POSTED=$($PSQL -c "SELECT count(*) FROM audit_log WHERE TRIM(TRAILING FROM action)='TXN_POSTED' AND business_date='$BDATE_PG'")
AUD_BATCH=$($PSQL -c "SELECT count(*) FROM audit_log WHERE TRIM(TRAILING FROM action)='POST_BATCH_DONE' AND business_date='$BDATE_PG'")
BR_RUN=$($PSQL -c "SELECT count(*) FROM batch_run WHERE batch_id='$BATCH_ID'")

DR_SUM=$($PSQL -c "SELECT COALESCE(SUM(debit_jpy),0) FROM postings WHERE business_date='$BDATE_PG'")
CR_SUM=$($PSQL -c "SELECT COALESCE(SUM(credit_jpy),0) FROM postings WHERE business_date='$BDATE_PG'")

echo "  [info] PG: transactions=$TXN_CNT postings=$POS_CNT audit_TXN_POSTED=$AUD_POSTED audit_BATCH=$AUD_BATCH batch_run=$BR_RUN"
echo "  [info] postings DR=$DR_SUM CR=$CR_SUM"

if [ "$MODE" = "smoke" ]; then
  check "decoded record count"   102 "$DEC_REC"
  check "valid record count"      90 "$VAL_REC"
  check "sorted = valid count"  "$VAL_REC" "$SOR_REC"
  check "ready record count"      92 "$RDY_REC"
  check "PG transactions"         90 "$TXN_CNT" ge
  check "PG postings"            180 "$POS_CNT" ge
  check "PG audit TXN_POSTED"     90 "$AUD_POSTED" ge
  check "PG audit BATCH_DONE"      1 "$AUD_BATCH" ge
  check "PG batch_run row exists"  1 "$BR_RUN"
  check "I2 conservation DR=CR"    "$DR_SUM" "$CR_SUM"
elif [ "$MODE" = "perf" ]; then
  check "decoded record count" 100002 "$DEC_REC"
  check "valid record count"    90000 "$VAL_REC"
  check "sorted = valid count" "$VAL_REC" "$SOR_REC"
  check "ready record count"    90002 "$RDY_REC"
  check "PG transactions"       90000 "$TXN_CNT" ge
  check "PG postings"          180000 "$POS_CNT" ge
  check "PG audit TXN_POSTED"   90000 "$AUD_POSTED" ge
  check "PG batch_run row exists"  1 "$BR_RUN"
  check "I2 conservation DR=CR"   "$DR_SUM" "$CR_SUM"
elif [ "$MODE" = "recon" ]; then
  E050_CNT=$(grep -ao 'E050' "$WORKDIR/txn-error.dat" 2>/dev/null | wc -l)
  RECON_POSTED=$($PSQL -c "SELECT count(*) FROM transactions WHERE TRIM(source_batch_id)='$BATCH_ID' AND source_seq BETWEEN 9001 AND 9006")
  DUP_POSTED=$($PSQL -c "SELECT count(*) FROM transactions WHERE TRIM(source_batch_id)='$BATCH_ID' AND source_seq=3")
  BATCH_TXN=$($PSQL -c "SELECT count(*) FROM transactions WHERE TRIM(source_batch_id)='$BATCH_ID'")
  echo "  [info] recon: E050=$E050_CNT recon_posted=$RECON_POSTED dup_posted=$DUP_POSTED batch_txn=$BATCH_TXN"
  check "ready record count (95 D + H + T)"   97 "$RDY_REC"
  check "merge duplicate E050 count"           2 "$E050_CNT"
  check "recon distinct posted (seq9001-9006)" 6 "$RECON_POSTED"
  check "duplicate seq3 NOT posted"            0 "$DUP_POSTED"
  check "batch transactions total"            95 "$BATCH_TXN"
  check "PG transactions"                      95 "$TXN_CNT" ge
  check "PG postings"                         190 "$POS_CNT" ge
  check "PG batch_run row exists"              1 "$BR_RUN"
  check "I2 conservation DR=CR"   "$DR_SUM" "$CR_SUM"
fi

echo "[verify] PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo "[verify] FAILED: ${FAILS[*]}" >&2
  exit 1
fi
exit 0
