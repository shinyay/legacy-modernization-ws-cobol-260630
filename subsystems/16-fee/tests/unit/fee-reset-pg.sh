#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q"

$PSQL -c "DELETE FROM postings WHERE business_date='2026-06-13' AND account_number IN ('0010010099301','0010010099302','0010010099303','0010010000004')"
$PSQL -c "DELETE FROM transactions WHERE source_system='FEE'"

$PSQL -c "UPDATE balances SET balance_jpy=1000000 WHERE account_number='0010010099301'"
$PSQL -c "UPDATE balances SET balance_jpy=100     WHERE account_number='0010010099302'"
$PSQL -c "UPDATE balances SET balance_jpy=5000    WHERE account_number='0010010099303'"
$PSQL -c "UPDATE balances SET balance_jpy=0       WHERE account_number='0010010000004'"
