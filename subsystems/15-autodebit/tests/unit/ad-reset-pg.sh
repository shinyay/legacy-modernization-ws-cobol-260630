#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q"
$PSQL -c "DELETE FROM postings WHERE business_date='2026-06-13'"
$PSQL -c "DELETE FROM transactions WHERE source_system='AUTODEBIT'"
$PSQL -c "DELETE FROM postings WHERE txn_id IN (SELECT txn_id FROM transactions WHERE source_system='FEE')"
$PSQL -c "DELETE FROM transactions WHERE source_system='FEE'"
$PSQL -c "UPDATE autodebit_schedules SET status='AC', consecutive_failures=0, next_due_date='2026-06-13', last_attempt_date=NULL, last_attempt_result=NULL WHERE instruction_id LIKE 'AD-TEST-%'"
$PSQL -c "UPDATE balances SET balance_jpy=100000 WHERE account_number='0010010099201'"
$PSQL -c "UPDATE balances SET balance_jpy=50     WHERE account_number='0010010099202'"
$PSQL -c "UPDATE balances SET balance_jpy=30000  WHERE account_number='0010010099203'"
$PSQL -c "UPDATE balances SET balance_jpy=10000  WHERE account_number='0010010099204'"
$PSQL -c "UPDATE balances SET balance_jpy=0 WHERE account_number='0010010000001'"
rm -f /tmp/ad-test/autodebit-failed.dat
