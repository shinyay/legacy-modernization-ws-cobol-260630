#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q"
$PSQL -c "TRUNCATE TABLE transactions, postings, audit_outbox RESTART IDENTITY CASCADE"
$PSQL -c "UPDATE balances SET balance_jpy = 100000, available_jpy = 100000, last_txn_id = NULL WHERE account_number IN ('0010010099001','0010010099002','0010010099003')"
$PSQL -c "UPDATE balances SET balance_jpy = 0 WHERE account_number IN ('0010010000001','0010010000002')"
