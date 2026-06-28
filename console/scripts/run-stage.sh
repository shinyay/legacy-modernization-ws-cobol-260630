#!/usr/bin/env bash
set -u

VERB="${1:?verb required}"
WORKDIR="${2:?workdir required}"
BATCH="${3:-E2E-CONS-01}"
BDATE="${4:-20260612}"

case "$BATCH" in
  *[!A-Za-z0-9-]*) echo "invalid batch id" >&2; exit 2 ;;
esac

WS=/workspace
E2E=$WS/tests/e2e
export PGHOST="${PGHOST:-postgres}" PGUSER="${PGUSER:-cobol}"
export PGPASSWORD="${PGPASSWORD:-cobol}" PGDATABASE="${PGDATABASE:-banking}"
export LD_PRELOAD="${LD_PRELOAD:-/usr/local/lib/libocesql.so}"
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

mkdir -p "$WORKDIR"
LOG="$WORKDIR/stage-${VERB}.log"

run() { "$@" < /dev/null > "$LOG" 2>&1; }

case "$VERB" in
  reset)
    if [ "${CONSOLE_ALLOW_DESTRUCTIVE_DEMO_RESET:-NO}" != "YES" ]; then
      echo "refused: set CONSOLE_ALLOW_DESTRUCTIVE_DEMO_RESET=YES" >&2
      exit 3
    fi
    {
      psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -tA -c \
        "SELECT pg_terminate_backend(a.pid) FROM pg_stat_activity a WHERE a.datname=current_database() AND a.state='idle in transaction' AND a.pid<>pg_backend_pid() AND EXISTS (SELECT 1 FROM pg_locks l JOIN pg_class c ON l.relation=c.oid WHERE l.pid=a.pid AND c.relname IN ('transactions','postings'))" >/dev/null 2>&1 || true
      bash "$WS/subsystems/22-operations/src/ops-seed-system-accounts.sh" &&
      E2E_PREP_USE_DELETE=1 bash "$E2E/scripts/e2e-prep-pg.sh" &&
      psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" \
        -c "DELETE FROM batch_run WHERE batch_id LIKE 'OPST%'" &&
      "$E2E/bin/e2e-seed-isam"
    } < /dev/null > "$LOG" 2>&1
    ;;
  fixture)
    E2E_TOTAL=100 E2E_VALID_RATIO=90 E2E_BATCH_ID="$BATCH" E2E_BDATE="$BDATE" \
      E2E_OUTPUT="$WORKDIR/txn-decoded.dat" \
      run "$E2E/bin/e2e-fixture-gen"
    ;;
  s10)
    run "$E2E/bin/e2e-driver" stage2 "$BATCH" "$BDATE" \
      "$WORKDIR/txn-decoded.dat" "$WORKDIR/txn-valid.dat" \
      "$WORKDIR/txn-error.dat" "$WORKDIR/txval.ckpt"
    ;;
  s11)
    run "$E2E/bin/e2e-driver" stage3 "$BATCH" "$BDATE" \
      "$WORKDIR/txn-valid.dat" "$WORKDIR/txn-sorted.dat" \
      "$WORKDIR/txsm-sort.ckpt"
    rc=$?
    [ $rc -ne 0 ] && exit $rc
    : > "$WORKDIR/txn-recon-prev.dat"
    mkdir -p "$WORKDIR/tmp"
    run "$E2E/bin/e2e-driver" stage4 "$BATCH" "$BDATE" \
      "$WORKDIR/txn-sorted.dat" "$WORKDIR/txn-recon-prev.dat" \
      "$WORKDIR/txn-ready.dat" "$WORKDIR/txn-error.dat" \
      "$WORKDIR/txsm-merge.ckpt" "$WORKDIR/tmp/txn-ready-d.tmp"
    ;;
  s12)
    bash "$WS/subsystems/22-operations/src/ops-batch-run-start.sh" \
      "$BATCH" "$BDATE" "TXPOST" < /dev/null > "$LOG" 2>&1
    rc=$?
    [ $rc -ne 0 ] && exit $rc
    "$E2E/bin/e2e-driver" stage5 "$BATCH" "$BDATE" \
      "$WORKDIR/txn-ready.dat" "$WORKDIR/txn-error.dat" \
      "$WORKDIR/txn-recon-defer.dat" "$WORKDIR/txpost.ckpt" \
      "$WORKDIR/dormancy.dat" < /dev/null >> "$LOG" 2>&1
    rc=$?
    posted=$(psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -tA \
      -v bd="$BDATE" 2>/dev/null <<'SQL'
SELECT count(*) FROM transactions WHERE business_date=to_date(:'bd','YYYYMMDD');
SQL
)
    posted=$(printf '%s' "$posted" | tr -dc '0-9')
    [ -z "$posted" ] && posted=0
    if [ "$rc" -eq 0 ]; then
      bash "$WS/subsystems/22-operations/src/ops-batch-run-complete.sh" \
        "$BATCH" "$BDATE" OK "$posted" 0 >> "$LOG" 2>&1 || true
    else
      bash "$WS/subsystems/22-operations/src/ops-batch-run-complete.sh" \
        "$BATCH" "$BDATE" FL "$posted" 1 >> "$LOG" 2>&1 || true
    fi
    exit $rc
    ;;
  *)
    echo "unknown verb: $VERB" >&2
    exit 2
    ;;
esac
