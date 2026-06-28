#!/usr/bin/env bash
set -u

WS=/workspace
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
E2E_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking
export LD_PRELOAD=/usr/local/lib/libocesql.so
PSQL="psql -h $PGHOST -U $PGUSER -d $PGDATABASE -tA"

E2E_BATCH_ID="E2E-LOSS-001"
E2E_BDATE=20260612
BDATE_PG=2026-06-12
WORKDIR=/tmp/e2e
DRAIN="$WS/shared/util/aud-drain/bin/aud-drain-main"

export COB_LIBRARY_PATH=\
$WS/subsystems/10-txnvalidate/bin:\
$WS/subsystems/11-txnsortmerge/bin:\
$WS/subsystems/12-txnpost/bin:\
$WS/subsystems/01-calendar/bin:\
$WS/subsystems/02-branch/bin:\
$WS/subsystems/05-product/bin:\
$WS/subsystems/08-account/bin:\
$WS/shared/util/aud-write/bin:\
$WS/shared/util/shared-log/bin

PASS=0; FAIL=0; declare -a FAILS=()
chk(){ if [ "$2" = "$3" ]; then echo "  [PASS] $1 = $3"; PASS=$((PASS+1));
  else echo "  [FAIL] $1 exp=$2 act=$3"; FAIL=$((FAIL+1)); FAILS+=("$1"); fi; }
aud_posted(){ $PSQL -c "SELECT count(*) FROM audit_log WHERE TRIM(TRAILING FROM action)='TXN_POSTED' AND business_date='$BDATE_PG'"; }
outbox_cnt(){ $PSQL -c "SELECT count(*) FROM audit_outbox WHERE TRIM(action)='TXN_POSTED'"; }
txn_cnt(){ $PSQL -c "SELECT count(*) FROM transactions WHERE business_date='$BDATE_PG'"; }

echo "=== E2E audit-outbox loss-recovery test (#2/B, AC4) ==="

echo "[phase 0] baseline smoke pipeline (drain ON) to build artifacts"
bash $SCRIPT_DIR/e2e-run.sh smoke > /tmp/e2e-loss-smoke.out 2>&1
if ! grep -aq "E2E mode=smoke COMPLETE" /tmp/e2e-loss-smoke.out; then
    echo "  [FAIL] baseline smoke pipeline did not complete"; tail -5 /tmp/e2e-loss-smoke.out; exit 1
fi
test -f "$WORKDIR/txn-ready.dat" || { echo "  [FAIL] txn-ready.dat missing"; exit 1; }

echo "[phase 1] re-post with AUD_DRAIN_SUPPRESS=YES (simulated crash before relay)"
bash $SCRIPT_DIR/e2e-prep-pg.sh > /dev/null 2>&1     # clean txns + audit_log + audit_outbox
bash $WS/subsystems/22-operations/src/ops-batch-run-start.sh "$E2E_BATCH_ID" "$E2E_BDATE" "TXPOST" > /dev/null 2>&1
AUD_DRAIN_SUPPRESS=YES $E2E_ROOT/bin/e2e-driver stage5 \
  "$E2E_BATCH_ID" "$E2E_BDATE" \
  "$WORKDIR/txn-ready.dat" "$WORKDIR/txn-error.dat" \
  "$WORKDIR/txn-recon-defer.dat" "$WORKDIR/txpost.ckpt" \
  "$WORKDIR/dormancy-repair.dat" > /tmp/e2e-loss-post.out 2>&1

chk "phase1 transactions posted"      90 "$(txn_cnt)"
chk "phase1 outbox holds intents"     90 "$(outbox_cnt)"
chk "phase1 audit_log LOST (missing)"  0 "$(aud_posted)"

echo "[phase 2] aud-drain-main recovery"
"$DRAIN" > /tmp/e2e-loss-drain1.out 2>&1; RC=$?
chk "phase2 drain exit=0"              0 "$RC"
chk "phase2 audit_log RECOVERED"      90 "$(aud_posted)"
chk "phase2 outbox emptied"            0 "$(outbox_cnt)"
grep -aq "drained=000000090" /tmp/e2e-loss-drain1.out \
  && { echo "  [PASS] phase2 reported drained=90"; PASS=$((PASS+1)); } \
  || { echo "  [FAIL] phase2 drained count"; FAIL=$((FAIL+1)); FAILS+=("p2-count"); }

echo "[phase 3] re-drain idempotency"
"$DRAIN" > /tmp/e2e-loss-drain2.out 2>&1
chk "phase3 audit_log still 90 (no dup)" 90 "$(aud_posted)"
grep -aq "drained=000000000" /tmp/e2e-loss-drain2.out \
  && { echo "  [PASS] phase3 reported drained=0"; PASS=$((PASS+1)); } \
  || { echo "  [FAIL] phase3 drained count"; FAIL=$((FAIL+1)); FAILS+=("p3-count"); }

echo "[phase 4] atomicity: forced retries => exactly one intent per posted txn"
bash $SCRIPT_DIR/e2e-prep-pg.sh > /dev/null 2>&1
bash $WS/subsystems/22-operations/src/ops-batch-run-start.sh "$E2E_BATCH_ID" "$E2E_BDATE" "TXPOST" > /dev/null 2>&1
AUD_DRAIN_SUPPRESS=YES TXPOST_FAULT_CONFLICT_N=2 TXPOST_MAX_RETRIES=5 \
  $E2E_ROOT/bin/e2e-driver stage5 \
  "$E2E_BATCH_ID" "$E2E_BDATE" \
  "$WORKDIR/txn-ready.dat" "$WORKDIR/txn-error.dat" \
  "$WORKDIR/txn-recon-defer.dat" "$WORKDIR/txpost.ckpt" \
  "$WORKDIR/dormancy-repair.dat" > /tmp/e2e-loss-retry.out 2>&1
chk "phase4 transactions posted"        90 "$(txn_cnt)"
chk "phase4 EXACTLY one intent per txn" 90 "$(outbox_cnt)"
"$DRAIN" > /dev/null 2>&1   # clean up the intents

echo "[phase 5] exhaustion: no post => no intent"
bash $SCRIPT_DIR/e2e-prep-pg.sh > /dev/null 2>&1
bash $WS/subsystems/22-operations/src/ops-batch-run-start.sh "$E2E_BATCH_ID" "$E2E_BDATE" "TXPOST" > /dev/null 2>&1
AUD_DRAIN_SUPPRESS=YES TXPOST_FAULT_CONFLICT_N=10 TXPOST_MAX_RETRIES=2 \
  $E2E_ROOT/bin/e2e-driver stage5 \
  "$E2E_BATCH_ID" "$E2E_BDATE" \
  "$WORKDIR/txn-ready.dat" "$WORKDIR/txn-error.dat" \
  "$WORKDIR/txn-recon-defer.dat" "$WORKDIR/txpost.ckpt" \
  "$WORKDIR/dormancy-repair.dat" > /tmp/e2e-loss-exhaust.out 2>&1
chk "phase5 nothing posted"   0 "$(txn_cnt)"
chk "phase5 no intent staged" 0 "$(outbox_cnt)"

echo "[verify] PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -gt 0 ]; then echo "FAILED: ${FAILS[*]}"; exit 1; fi
echo "=== E2E audit-outbox loss-recovery test COMPLETE ($PASS/$PASS) ==="
