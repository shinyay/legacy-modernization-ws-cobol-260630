#!/usr/bin/env bash
set -euo pipefail

export PGHOST="${PGHOST:-postgres}" PGUSER="${PGUSER:-cobol}"
export PGPASSWORD="${PGPASSWORD:-cobol}" PGDATABASE="${PGDATABASE:-banking}"
PSQL="psql -h $PGHOST -U $PGUSER -d $PGDATABASE -q"

if [ "${1:-}" = "--clear" ]; then
  $PSQL -c "DELETE FROM batch_run WHERE batch_id LIKE 'DEMO-%'"
  echo "[seed-batch-demo] cleared DEMO-* batch_run rows"
  exit 0
fi

BD="2026-06-12"
$PSQL <<SQL
INSERT INTO batch_run
  (batch_id, business_date, started_ts, completed_ts, status,
   current_step, last_failed_step, txns_posted, interest_accounts, errors_count, notes)
VALUES
  ('DEMO-OK-DAILY ', '${BD}', '${BD} 01:00:00', '${BD} 01:03:10', 'OK',
   'STATEMENT', NULL, 90, 12, 0, 'demo: clean daily batch'),
  ('DEMO-RN-DAILY ', '${BD}', '${BD} 02:00:00', NULL, 'RN',
   'TXPOST', NULL, NULL, NULL, 0, 'demo: batch still running'),
  ('DEMO-FL-DAILY ', '${BD}', '${BD} 03:00:00', '${BD} 03:00:40', 'FL',
   'TXPOST', 'TXPOST', 12, NULL, 7, 'demo: failed mid-post'),
  ('DEMO-AB-DAILY ', '${BD}', '${BD} 04:00:00', '${BD} 04:00:05', 'AB',
   'VALIDATE', 'VALIDATE', 0, NULL, 1, 'demo: operator aborted')
ON CONFLICT (batch_id) DO UPDATE SET
   status=EXCLUDED.status, current_step=EXCLUDED.current_step,
   last_failed_step=EXCLUDED.last_failed_step, txns_posted=EXCLUDED.txns_posted,
   completed_ts=EXCLUDED.completed_ts, errors_count=EXCLUDED.errors_count;
SQL
echo "[seed-batch-demo] seeded DEMO-* batch_run rows (OK/RN/FL/AB) on ${BD}"
