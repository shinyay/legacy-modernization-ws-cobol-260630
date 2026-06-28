#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q"
$PSQL -c "DELETE FROM postings WHERE business_date='2026-06-30'"
$PSQL -c "DELETE FROM transactions WHERE source_system='INTEREST'"
$PSQL -c "UPDATE interest_accruals SET status='AC', posted_txn_id=NULL WHERE business_date BETWEEN '2026-06-01' AND '2026-06-30' AND account_number LIKE '001001%'"
$PSQL -c "UPDATE balances SET balance_jpy=100000 WHERE account_number='0010010099101'"
$PSQL -c "UPDATE balances SET balance_jpy=200000 WHERE account_number='0010010099102'"
$PSQL -c "UPDATE balances SET balance_jpy=500000 WHERE account_number='0010010099103'"
$PSQL -c "UPDATE balances SET balance_jpy=0      WHERE account_number='0010010000003'"
