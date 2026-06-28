#!/usr/bin/env bash
set -e
BATCH_ID="$1"
BDATE="${2//-/}"  # strip hyphens for normalization
BDATE_PG="${BDATE:0:4}-${BDATE:4:2}-${BDATE:6:2}"
STEP="${3:-}"
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q"

if [ -n "$STEP" ]; then
  $PSQL -v batch="$BATCH_ID" -v bdate="$BDATE_PG" -v step="$STEP" <<'SQL'
INSERT INTO batch_run (batch_id, business_date, started_ts, status, current_step, errors_count)
VALUES (:'batch', :'bdate', NOW(), 'RN', :'step', 0)
ON CONFLICT (batch_id) DO UPDATE
  SET started_ts=NOW(), status='RN', current_step=:'step', completed_ts=NULL;
SQL
else
  $PSQL -v batch="$BATCH_ID" -v bdate="$BDATE_PG" <<'SQL'
INSERT INTO batch_run (batch_id, business_date, started_ts, status, errors_count)
VALUES (:'batch', :'bdate', NOW(), 'RN', 0)
ON CONFLICT (batch_id) DO UPDATE
  SET started_ts=NOW(), status='RN', completed_ts=NULL;
SQL
fi
echo "[ops-batch-run-start] batch=$BATCH_ID bdate=$BDATE_PG status=RN"
