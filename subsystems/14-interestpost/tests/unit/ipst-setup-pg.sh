#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q"

$PSQL -c "DELETE FROM postings WHERE business_date='2026-06-30'"
$PSQL -c "DELETE FROM transactions WHERE source_system='INTEREST'"
$PSQL -c "DELETE FROM interest_accruals WHERE business_date BETWEEN '2026-06-01' AND '2026-06-30' AND account_number LIKE '001001%'"
$PSQL -c "DELETE FROM audit_log WHERE TRIM(TRAILING FROM action) IN ('INTEREST_POSTED','IPST_MTH_SUMMARY') AND business_date='2026-06-30'"

$PSQL -c "INSERT INTO customers (cust_id, cust_name, cust_name_kana, cust_status, tier) VALUES ('9999000099', 'IPST TEST', 'IPST TEST', 'A', 'B') ON CONFLICT (cust_id) DO NOTHING"

$PSQL -c "INSERT INTO accounts (acct_number, acct_name, branch_code, product_code, acct_status, cust_id, opened_date) VALUES
  ('0010010099101', 'IPST T1', '001', '001', 'A', '9999000099', '2026-01-01'),
  ('0010010099102', 'IPST T2', '001', '001', 'A', '9999000099', '2026-01-01'),
  ('0010010099103', 'IPST T3-003', '001', '003', 'A', '9999000099', '2026-01-01')
  ON CONFLICT (acct_number) DO UPDATE SET acct_status='A', product_code=EXCLUDED.product_code"

$PSQL -c "INSERT INTO balances (account_number, balance_jpy, available_jpy) VALUES
  ('0010010099101', 100000, 100000),
  ('0010010099102', 200000, 200000),
  ('0010010099103', 500000, 500000)
  ON CONFLICT (account_number) DO UPDATE SET balance_jpy=EXCLUDED.balance_jpy"

$PSQL -c "INSERT INTO balances (account_number, balance_jpy, available_jpy) VALUES ('0010010000003', 0, 0) ON CONFLICT (account_number) DO UPDATE SET balance_jpy=0"

$PSQL -c "INSERT INTO interest_accruals (business_date, account_number, product_code, principal_jpy, rate, days, accrued_jpy, status) VALUES
  ('2026-06-15', '0010010099101', '001', 100000, 0.0010, 1, 3, 'AC'),
  ('2026-06-20', '0010010099101', '001', 100000, 0.0010, 1, 3, 'AC'),
  ('2026-06-25', '0010010099101', '001', 100000, 0.0010, 1, 3, 'AC'),
  ('2026-06-15', '0010010099102', '001', 200000, 0.0010, 1, 5, 'AC'),
  ('2026-06-20', '0010010099102', '001', 200000, 0.0010, 1, 5, 'AC'),
  ('2026-06-25', '0010010099102', '001', 200000, 0.0010, 1, 5, 'AC'),
  ('2026-06-15', '0010010099103', '003', 500000, 0.0050, 1, 68, 'AC'),
  ('2026-06-20', '0010010099103', '003', 500000, 0.0050, 1, 68, 'AC'),
  ('2026-06-25', '0010010099103', '003', 500000, 0.0050, 1, 68, 'AC')"

echo "[ipst-setup-pg] done"
