#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q -tA"

if [ "${E2E_PREP_USE_DELETE:-0}" = "1" ]; then
  $PSQL -c "DELETE FROM postings"
  $PSQL -c "DELETE FROM transactions"
else
  $PSQL -c "TRUNCATE TABLE transactions, postings RESTART IDENTITY CASCADE"
fi
$PSQL -c "DELETE FROM batch_run WHERE batch_id LIKE 'E2E-%' OR batch_id LIKE 'BATCH-E2E-%'"
$PSQL -c "DELETE FROM audit_log WHERE TRIM(TRAILING FROM action) IN ('TXN_POSTED','POST_BATCH_DONE','TXN_REVERSED') AND business_date='2026-06-12'"
$PSQL -c "DELETE FROM audit_outbox"

$PSQL -c "INSERT INTO customers (cust_id, cust_name, cust_name_kana, cust_status, tier, created_at, updated_at) VALUES ('9999000099', 'E2E TEST', 'E2EテストJP', 'A', 'B', NOW(), NOW()) ON CONFLICT (cust_id) DO NOTHING"

for ACCT in 0010010099001 0010010099002 0010010099003; do
  $PSQL -c "INSERT INTO accounts (acct_number, acct_name, branch_code, product_code, acct_status, cust_id, opened_date, created_at, updated_at) VALUES ('$ACCT', 'E2E TEST', '001', '001', 'A', '9999000099', '2026-06-01', NOW(), NOW()) ON CONFLICT (acct_number) DO UPDATE SET acct_status='A'"
  $PSQL -c "INSERT INTO balances (account_number, balance_jpy, available_jpy, last_business_date, updated_ts) VALUES ('$ACCT', 100000, 100000, '2026-06-01', NOW()) ON CONFLICT (account_number) DO UPDATE SET balance_jpy=100000, available_jpy=100000, last_txn_id=NULL"
done

$PSQL -c "UPDATE balances SET balance_jpy = 0 WHERE account_number IN ('0010010000001','0010010000002','0010010000003','0010010000004')"

echo "[e2e-prep-pg] complete"
