#!/usr/bin/env bash
set -e
BATCH_ID="$1"
BDATE="${2//-/}"
BDATE_PG="${BDATE:0:4}-${BDATE:4:2}-${BDATE:6:2}"
STATUS="$3"
TXNS_POSTED="${4:-0}"
ERR_COUNT="${5:-0}"

case "$STATUS" in
  OK|FL|AB) ;;
  *) echo "[ops-batch-run-complete] invalid status '$STATUS'; must be OK/FL/AB" >&2; exit 1;;
esac

export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q"
$PSQL -v status="$STATUS" -v txns="$TXNS_POSTED" -v errs="$ERR_COUNT" \
      -v batch="$BATCH_ID" -v bdate="$BDATE_PG" <<'SQL'
UPDATE batch_run
   SET completed_ts=NOW(),
       status=:'status',
       txns_posted=:'txns'::integer,
       errors_count=:'errs'::integer
 WHERE batch_id=:'batch'
   AND business_date=:'bdate';
SQL
echo "[ops-batch-run-complete] batch=$BATCH_ID bdate=$BDATE_PG status=$STATUS txns=$TXNS_POSTED errs=$ERR_COUNT"
