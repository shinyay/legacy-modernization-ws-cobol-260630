#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q"

$PSQL -c "DELETE FROM postings WHERE txn_id IN (SELECT txn_id FROM transactions WHERE source_batch_id='EOD20260613-DP')"
$PSQL -c "DELETE FROM transactions WHERE source_batch_id='EOD20260613-DP'"
$PSQL -c "DELETE FROM autodebit_schedules WHERE instruction_id LIKE 'AD-DUP-%'"
$PSQL -c "UPDATE autodebit_schedules SET status='SP' WHERE status='AC'"
$PSQL -c "UPDATE balances SET balance_jpy=100000, available_jpy=100000 WHERE account_number='0010010099201'"
$PSQL -c "INSERT INTO autodebit_schedules (instruction_id, payer_account, payee_name, amount_jpy, frequency, next_due_date, status, consecutive_failures) VALUES ('AD-DUP-001', '0010010099201', 'DUP PAYEE A', 100, 'M', '2026-06-13', 'AC', 0), ('AD-DUP-002', '0010010099201', 'DUP PAYEE B', 200, 'M', '2026-06-13', 'AC', 0)"
