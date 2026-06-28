#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q"

$PSQL -c "DELETE FROM postings WHERE business_date BETWEEN '2026-06-01' AND '2026-06-30' AND account_number IN ('0010010099401','0010010099402','0010010099403','0010010099404','0010010099405')"
$PSQL -c "DELETE FROM transactions WHERE source_batch_id LIKE 'STMT-TEST%'"
$PSQL -c "DELETE FROM balances WHERE account_number IN ('0010010099401','0010010099402','0010010099403','0010010099404','0010010099405')"
$PSQL -c "DELETE FROM accounts WHERE acct_number IN ('0010010099401','0010010099402','0010010099403','0010010099404','0010010099405')"

$PSQL -c "INSERT INTO customers (cust_id, cust_name, cust_name_kana, cust_status, tier) VALUES ('9999000099', 'STMT TEST', 'STMT TEST', 'A', 'B') ON CONFLICT (cust_id) DO NOTHING"

$PSQL -c "INSERT INTO accounts (acct_number, acct_name, branch_code, product_code, acct_status, cust_id, opened_date) VALUES
  ('0010010099401', 'STMT T1', '001', '001', 'A', '9999000099', '2026-01-01'),
  ('0010010099402', 'STMT T2', '001', '001', 'A', '9999000099', '2026-01-01'),
  ('0010010099403', 'STMT T3', '001', '001', 'A', '9999000099', '2026-01-01'),
  ('0010010099404', 'STMT T4', '001', '001', 'A', '9999000099', '2026-01-01'),
  ('0010010099405', 'STMT T5 Empty', '001', '001', 'A', '9999000099', '2026-01-01')
  ON CONFLICT (acct_number) DO UPDATE SET acct_status=EXCLUDED.acct_status"

$PSQL -c "INSERT INTO balances (account_number, balance_jpy, available_jpy, last_business_date) VALUES
  ('0010010099401', 100000, 100000, '2026-06-13'),
  ('0010010099402',  50000,  50000, '2026-06-13'),
  ('0010010099403', 200000, 200000, '2026-06-13'),
  ('0010010099404',  10000,  10000, '2026-06-13'),
  ('0010010099405',   5000,   5000, '2026-06-13')
  ON CONFLICT (account_number) DO UPDATE SET balance_jpy=EXCLUDED.balance_jpy, last_business_date=EXCLUDED.last_business_date"

$PSQL -c "INSERT INTO transactions
  (txn_id, business_date, system_ts, category, account_number, amount_jpy, currency,
   description, source_system, source_batch_id, source_seq, status, created_by, created_ts)
  VALUES
  ('20260613ST00099401', '2026-06-13', NOW(), '10', '0010010099401', 10000,  'JPY', 'deposit T1-1', 'BATCH', 'STMT-TEST-DEP ', '1', 'PT', 'test', NOW()),
  ('20260613ST00099402', '2026-06-13', NOW(), '20', '0010010099401',  5000,  'JPY', 'withdraw T1-2','BATCH', 'STMT-TEST-DEP ', '2', 'PT', 'test', NOW()),
  ('20260613ST00099403', '2026-06-13', NOW(), '10', '0010010099402', 30000,  'JPY', 'deposit T2-1', 'BATCH', 'STMT-TEST-DEP ', '3', 'PT', 'test', NOW()),
  ('20260613ST00099404', '2026-06-13', NOW(), '30', '0010010099402', 10000,  'JPY', 'transfer T2-2','BATCH', 'STMT-TEST-DEP ', '4', 'PT', 'test', NOW()),
  ('20260613ST00099405', '2026-06-13', NOW(), '40', '0010010099403', 80000,  'JPY', 'wire T3-1',    'BATCH', 'STMT-TEST-DEP ', '5', 'PT', 'test', NOW()),
  ('20260613ST00099406', '2026-06-13', NOW(), '10', '0010010099403', 20000,  'JPY', 'deposit T3-2', 'BATCH', 'STMT-TEST-DEP ', '6', 'PT', 'test', NOW()),
  ('20260613ST00099407', '2026-06-13', NOW(), '50', '0010010099403',   500,  'JPY', 'interest T3-3','BATCH', 'STMT-TEST-DEP ', '7', 'PT', 'test', NOW()),
  ('20260613ST00099408', '2026-06-13', NOW(), '20', '0010010099404',  2000,  'JPY', 'withdraw T4-1','BATCH', 'STMT-TEST-DEP ', '8', 'PT', 'test', NOW()),
  ('20260613ST00099409', '2026-06-13', NOW(), '60', '0010010099404',   220,  'JPY', 'fee T4-2',     'BATCH', 'STMT-TEST-DEP ', '9', 'PT', 'test', NOW()),
  ('20260613ST00099410', '2026-06-13', NOW(), '10', '0010010099404',  8000,  'JPY', 'deposit T4-3', 'BATCH', 'STMT-TEST-DEP ', '10','PT', 'test', NOW())
  ON CONFLICT (txn_id) DO NOTHING"

$PSQL -c "INSERT INTO postings (posting_id, txn_id, line_no, account_number, debit_jpy, credit_jpy, posting_role, business_date, created_ts) VALUES
  ('20260613ST0009940101', '20260613ST00099401', 1, '0010010099401',     0, 10000, 'CR', '2026-06-13', NOW()),
  ('20260613ST0009940201', '20260613ST00099402', 1, '0010010099401',  5000,    0, 'DR', '2026-06-13', NOW()),
  ('20260613ST0009940301', '20260613ST00099403', 1, '0010010099402',     0, 30000, 'CR', '2026-06-13', NOW()),
  ('20260613ST0009940401', '20260613ST00099404', 1, '0010010099402', 10000,    0, 'DR', '2026-06-13', NOW()),
  ('20260613ST0009940501', '20260613ST00099405', 1, '0010010099403', 80000,    0, 'DR', '2026-06-13', NOW()),
  ('20260613ST0009940601', '20260613ST00099406', 1, '0010010099403',     0, 20000, 'CR', '2026-06-13', NOW()),
  ('20260613ST0009940701', '20260613ST00099407', 1, '0010010099403',     0,   500, 'CR', '2026-06-13', NOW()),
  ('20260613ST0009940801', '20260613ST00099408', 1, '0010010099404',  2000,    0, 'DR', '2026-06-13', NOW()),
  ('20260613ST0009940901', '20260613ST00099409', 1, '0010010099404',   220,    0, 'DR', '2026-06-13', NOW()),
  ('20260613ST0009941001', '20260613ST00099410', 1, '0010010099404',     0,  8000, 'CR', '2026-06-13', NOW())
  ON CONFLICT (posting_id) DO NOTHING"

echo "[stmt-setup-pg] done"
