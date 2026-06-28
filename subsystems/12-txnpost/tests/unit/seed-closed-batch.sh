#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q"
$PSQL -c "INSERT INTO batch_run (batch_id, business_date, started_ts, completed_ts, status) VALUES ('BATCH-CLOSED-1', '2026-06-15', NOW(), NOW(), 'OK') ON CONFLICT (batch_id) DO NOTHING"
