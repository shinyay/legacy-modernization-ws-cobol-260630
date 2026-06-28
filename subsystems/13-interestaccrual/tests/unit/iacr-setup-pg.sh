#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q"

$PSQL -c "DELETE FROM interest_accruals WHERE account_number LIKE '001001009%'"
$PSQL -c "DELETE FROM interest_accruals WHERE business_date IN ('2026-06-12','2026-06-13')"
$PSQL -c "DELETE FROM audit_log WHERE TRIM(TRAILING FROM action)='IACR_DAILY_SUMMARY' AND business_date IN ('2026-06-12','2026-06-13')"

$PSQL -c "INSERT INTO customers (cust_id, cust_name, cust_name_kana, cust_status, tier) VALUES ('9999000099', 'IACR TEST CUST', 'IACR TEST', 'A', 'B') ON CONFLICT (cust_id) DO NOTHING"

$PSQL -c "INSERT INTO accounts (acct_number, acct_name, branch_code, product_code, acct_status, cust_id, opened_date) VALUES
  ('0010010099001', 'IACR T1 A-Sav', '001', '001', 'A', '9999000099', '2026-01-01'),
  ('0010010099002', 'IACR T2 D-Sav', '001', '001', 'D', '9999000099', '2026-01-01'),
  ('0010010099003', 'IACR T3 A-Chk', '001', '003', 'A', '9999000099', '2026-01-01'),
  ('0010010099004', 'IACR T4 P-Sav', '001', '001', 'P', '9999000099', '2026-01-01'),
  ('0010010099005', 'IACR T5 C-Sav', '001', '001', 'C', '9999000099', '2026-01-01'),
  ('0010010099006', 'IACR T6 S-Sav', '001', '001', 'S', '9999000099', '2026-01-01'),
  ('0010010099007', 'IACR T7 A-Zero', '001', '001', 'A', '9999000099', '2026-01-01')
  ON CONFLICT (acct_number) DO UPDATE SET acct_status=EXCLUDED.acct_status, product_code=EXCLUDED.product_code"

$PSQL -c "INSERT INTO balances (account_number, balance_jpy, available_jpy) VALUES
  ('0010010099001', 1000000, 1000000),
  ('0010010099002', 500000, 500000),
  ('0010010099003', 200000, 200000),
  ('0010010099004', 100000, 100000),
  ('0010010099005', 0, 0),
  ('0010010099006', 50000, 50000),
  ('0010010099007', 0, 0)
  ON CONFLICT (account_number) DO UPDATE SET balance_jpy=EXCLUDED.balance_jpy"

cobc -x -free -W -o /tmp/iacr-seed-isam \
    /workspace/subsystems/13-interestaccrual/tests/unit/iacr-seed-isam.cob 2>/dev/null
[ -x /tmp/iacr-seed-isam ] && /tmp/iacr-seed-isam || true
echo "[iacr-setup-pg] done"
