#!/usr/bin/env bash
set -e

MODE="${1:-smoke}"
case "$MODE" in
  smoke) E2E_TOTAL=100;    BATCH_SUFFIX="SMOK" ;;
  perf)  E2E_TOTAL=100000; BATCH_SUFFIX="PERF" ;;
  recon) E2E_TOTAL=100;    BATCH_SUFFIX="RECN" ;;
  *) echo "usage: $0 {smoke|perf|recon}"; exit 1 ;;
esac

E2E_VALID_RATIO=90
E2E_BATCH_ID="E2E-${BATCH_SUFFIX}-001"   # 14 chars exactly
E2E_BDATE=20260612
WORKDIR=/tmp/e2e
RESULTS=$WORKDIR/results
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
E2E_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WS=/workspace

mkdir -p $WORKDIR $RESULTS
rm -f $WORKDIR/*.dat $WORKDIR/*.ckpt $WORKDIR/*.md $RESULTS/*.json

export E2E_TOTAL E2E_VALID_RATIO E2E_BATCH_ID E2E_BDATE
export E2E_OUTPUT=$WORKDIR/txn-decoded.dat
export PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking
export LD_PRELOAD=/usr/local/lib/libocesql.so

COB_LIBRARY_PATH=\
$WS/subsystems/10-txnvalidate/bin:\
$WS/subsystems/11-txnsortmerge/bin:\
$WS/subsystems/12-txnpost/bin:\
$WS/subsystems/01-calendar/bin:\
$WS/subsystems/02-branch/bin:\
$WS/subsystems/05-product/bin:\
$WS/subsystems/08-account/bin:\
$WS/shared/util/aud-write/bin:\
$WS/shared/util/shared-log/bin
export COB_LIBRARY_PATH

echo "=== Phase 4e E2E run: mode=$MODE total=$E2E_TOTAL ratio=$E2E_VALID_RATIO ==="

echo "[stage 0] PG reset + system + test seeds"
bash $WS/subsystems/22-operations/src/ops-seed-system-accounts.sh > /dev/null 2>&1
bash $SCRIPT_DIR/e2e-prep-pg.sh
$E2E_ROOT/bin/e2e-seed-isam

echo "[stage 1] generate fixture E2E_OUTPUT=$E2E_OUTPUT"
STAGE1_START=$(date +%s.%N)
$E2E_ROOT/bin/e2e-fixture-gen
STAGE1_END=$(date +%s.%N)
STAGE1_SEC=$(awk "BEGIN {printf \"%.3f\", $STAGE1_END - $STAGE1_START}")
echo "  elapsed: ${STAGE1_SEC}s"

echo "[stage 2] TXVAL-VALIDATE-BATCH"
STAGE2_START=$(date +%s.%N)
$E2E_ROOT/bin/e2e-driver stage2 \
  "$E2E_BATCH_ID" "$E2E_BDATE" \
  "$WORKDIR/txn-decoded.dat" "$WORKDIR/txn-valid.dat" \
  "$WORKDIR/txn-error.dat" "$WORKDIR/txval.ckpt" \
  > $RESULTS/stage2.out
cat $RESULTS/stage2.out
STAGE2_END=$(date +%s.%N)
STAGE2_SEC=$(awk "BEGIN {printf \"%.3f\", $STAGE2_END - $STAGE2_START}")
echo "  elapsed: ${STAGE2_SEC}s"

echo "[stage 3] TXSM-SORT-BATCH"
STAGE3_START=$(date +%s.%N)
$E2E_ROOT/bin/e2e-driver stage3 \
  "$E2E_BATCH_ID" "$E2E_BDATE" \
  "$WORKDIR/txn-valid.dat" "$WORKDIR/txn-sorted.dat" \
  "$WORKDIR/txsm-sort.ckpt" \
  > $RESULTS/stage3.out
cat $RESULTS/stage3.out
STAGE3_END=$(date +%s.%N)
STAGE3_SEC=$(awk "BEGIN {printf \"%.3f\", $STAGE3_END - $STAGE3_START}")
echo "  elapsed: ${STAGE3_SEC}s"

mkdir -p $WORKDIR/tmp
if [ "$MODE" = "recon" ]; then
  echo "[stage 4] TXSM-MERGE-BATCH (= non-empty recon-prev; #42)"
  E2E_RECON_PATH=$WORKDIR/txn-recon-prev.dat \
  E2E_BATCH_ID="$E2E_BATCH_ID" E2E_BDATE="$E2E_BDATE" \
    $E2E_ROOT/bin/e2e-recon-gen
else
  echo "[stage 4] TXSM-MERGE-BATCH (= empty recon-prev)"
  : > $WORKDIR/txn-recon-prev.dat
fi
STAGE4_START=$(date +%s.%N)
$E2E_ROOT/bin/e2e-driver stage4 \
  "$E2E_BATCH_ID" "$E2E_BDATE" \
  "$WORKDIR/txn-sorted.dat" "$WORKDIR/txn-recon-prev.dat" \
  "$WORKDIR/txn-ready.dat" "$WORKDIR/txn-error.dat" \
  "$WORKDIR/txsm-merge.ckpt" "$WORKDIR/tmp/txn-ready-d-only.tmp" \
  > $RESULTS/stage4.out
cat $RESULTS/stage4.out
STAGE4_END=$(date +%s.%N)
STAGE4_SEC=$(awk "BEGIN {printf \"%.3f\", $STAGE4_END - $STAGE4_START}")
echo "  elapsed: ${STAGE4_SEC}s"

echo "[stage 5] TXPOST-RUN-BATCH (= with batch_run start/complete)"
bash $WS/subsystems/22-operations/src/ops-batch-run-start.sh \
  "$E2E_BATCH_ID" "$E2E_BDATE" "TXPOST"
STAGE5_START=$(date +%s.%N)
$E2E_ROOT/bin/e2e-driver stage5 \
  "$E2E_BATCH_ID" "$E2E_BDATE" \
  "$WORKDIR/txn-ready.dat" "$WORKDIR/txn-error.dat" \
  "$WORKDIR/txn-recon-defer.dat" "$WORKDIR/txpost.ckpt" \
  "$WORKDIR/dormancy-repair.dat" \
  > $RESULTS/stage5.out
cat $RESULTS/stage5.out
STAGE5_END=$(date +%s.%N)
STAGE5_SEC=$(awk "BEGIN {printf \"%.3f\", $STAGE5_END - $STAGE5_START}")
echo "  elapsed: ${STAGE5_SEC}s"

POSTED=$(grep -oE '"records_posted":[0-9]+' $RESULTS/stage5.out | head -1 | grep -oE '[0-9]+$' || echo 0)
TX_STATUS=$(grep -oE '"status":"[0-9]+"' $RESULTS/stage5.out | head -1 | grep -oE '[0-9]+' || echo 16)
case "$TX_STATUS" in
  00|04) BR_STATUS="OK" ;;
  *) BR_STATUS="FL" ;;
esac
bash $WS/subsystems/22-operations/src/ops-batch-run-complete.sh \
  "$E2E_BATCH_ID" "$E2E_BDATE" "$BR_STATUS" "$POSTED" 0

echo "[stage 6] verify"
bash $SCRIPT_DIR/e2e-verify.sh "$MODE" "$E2E_BATCH_ID" "$E2E_BDATE" "$WORKDIR" "$RESULTS"

TOTAL_SEC=$(awk "BEGIN {printf \"%.3f\", $STAGE1_SEC + $STAGE2_SEC + $STAGE3_SEC + $STAGE4_SEC + $STAGE5_SEC}")
cat > $RESULTS/perf.json <<EOF
{
  "mode": "$MODE",
  "total_records": $E2E_TOTAL,
  "valid_ratio": $E2E_VALID_RATIO,
  "batch_id": "$E2E_BATCH_ID",
  "stages": {
    "fixture":     $STAGE1_SEC,
    "txval":       $STAGE2_SEC,
    "txsm_sort":   $STAGE3_SEC,
    "txsm_merge":  $STAGE4_SEC,
    "txpost":      $STAGE5_SEC
  },
  "total_sec": $TOTAL_SEC
}
EOF
echo "[perf] total wall = ${TOTAL_SEC}s -> $RESULTS/perf.json"
echo "=== E2E mode=$MODE COMPLETE ==="
