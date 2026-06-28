#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q"
$PSQL -c "INSERT INTO customers (cust_id, cust_name, cust_name_kana, cust_status, tier) VALUES ('9999000099', 'TEST CUST', 'TEST', 'A', 'B') ON CONFLICT (cust_id) DO NOTHING"
$PSQL -c "INSERT INTO accounts (acct_number, acct_name, branch_code, product_code, acct_status, cust_id, opened_date) VALUES ('0010010099001', 'TEST ACCT 1', '001', '001', 'A', '9999000099', '2026-01-01'), ('0010010099002', 'TEST ACCT 2', '001', '001', 'A', '9999000099', '2026-01-01'), ('0010010099003', 'DORM ACCT 3', '001', '001', 'D', '9999000099', '2026-01-01') ON CONFLICT (acct_number) DO NOTHING"
$PSQL -c "INSERT INTO balances (account_number, balance_jpy, available_jpy) VALUES ('0010010099001', 100000, 100000), ('0010010099002', 100000, 100000), ('0010010099003', 100000, 100000) ON CONFLICT (account_number) DO NOTHING"

cobc -x -free -W -o /tmp/seed-test-isam \
    /workspace/subsystems/12-txnpost/tests/unit/seed-test-isam.cob \
    2>/dev/null || true
[ -x /tmp/seed-test-isam ] && /tmp/seed-test-isam || true
