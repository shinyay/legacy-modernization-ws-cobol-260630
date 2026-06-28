#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q"

$PSQL -c "DELETE FROM postings WHERE business_date='2026-06-13' AND account_number IN ('0010010099301','0010010099302','0010010099303','0010010000004')"
$PSQL -c "DELETE FROM transactions WHERE source_system='FEE'"
$PSQL -c "DELETE FROM transactions WHERE source_system='BATCH' AND source_batch_id LIKE 'FEE-TEST-%'"
$PSQL -c "DELETE FROM audit_log WHERE TRIM(TRAILING FROM action) IN ('FEE_CHARGED','FEE_DAILY_SUMM') AND business_date='2026-06-13'"
$PSQL -c "DELETE FROM audit_outbox"

$PSQL -c "INSERT INTO customers (cust_id, cust_name, cust_name_kana, cust_status, tier) VALUES ('9999000099', 'FEE TEST', 'FEE TEST', 'A', 'B') ON CONFLICT (cust_id) DO NOTHING"

$PSQL -c "INSERT INTO accounts (acct_number, acct_name, branch_code, product_code, acct_status, cust_id, opened_date) VALUES
  ('0010010099301', 'FEE T1-Active', '001', '001', 'A', '9999000099', '2026-01-01'),
  ('0010010099302', 'FEE T2-LowBal', '001', '001', 'A', '9999000099', '2026-01-01'),
  ('0010010099303', 'FEE T3-Closed', '001', '001', 'C', '9999000099', '2026-01-01')
  ON CONFLICT (acct_number) DO UPDATE SET acct_status=EXCLUDED.acct_status"

$PSQL -c "INSERT INTO balances (account_number, balance_jpy, available_jpy) VALUES
  ('0010010099301', 1000000, 1000000),
  ('0010010099302', 100,     100),
  ('0010010099303', 5000,    5000)
  ON CONFLICT (account_number) DO UPDATE SET balance_jpy=EXCLUDED.balance_jpy, available_jpy=EXCLUDED.available_jpy"

$PSQL -c "INSERT INTO transactions
  (txn_id, business_date, system_ts, category, account_number, amount_jpy, currency,
   description, source_system, source_batch_id, source_seq, status, created_by, created_ts)
  VALUES
  ('20260613FT00000001', '2026-06-13', NOW(), '40', '0010010099301', 5000,   'JPY', 'src wire 1', 'BATCH', 'FEE-TEST-SRC ', '1', 'PT', 'test', NOW()),
  ('20260613FT00000002', '2026-06-13', NOW(), '40', '0010010099301', 50000,  'JPY', 'src wire 2', 'BATCH', 'FEE-TEST-SRC ', '2', 'PT', 'test', NOW()),
  ('20260613FT00000003', '2026-06-13', NOW(), '40', '0010010099301', 200000, 'JPY', 'src wire 3', 'BATCH', 'FEE-TEST-SRC ', '3', 'PT', 'test', NOW()),
  ('20260613FT00000004', '2026-06-13', NOW(), '30', '0010010099301', 10000,  'JPY', 'src xfer 1', 'BATCH', 'FEE-TEST-SRC ', '4', 'PT', 'test', NOW()),
  ('20260613FT00000005', '2026-06-13', NOW(), '40', '0010010099302', 50000,  'JPY', 'src wire 5', 'BATCH', 'FEE-TEST-SRC ', '5', 'PT', 'test', NOW()),
  ('20260613FT00000006', '2026-06-13', NOW(), '40', '0010010099303', 50000,  'JPY', 'src wire 6', 'BATCH', 'FEE-TEST-SRC ', '6', 'PT', 'test', NOW())
  ON CONFLICT (txn_id) DO NOTHING"

cat > /tmp/fee-seed-isam.cob <<'COB'
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FEE-SEED-ISAM.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE
               ASSIGN TO "/workspace/subsystems/08-account/data/account.idx"
               ORGANIZATION IS INDEXED ACCESS MODE IS RANDOM
               RECORD KEY IS ACCT-REC-NUMBER
               ALTERNATE RECORD KEY IS ACCT-REC-CUST-ID WITH DUPLICATES
               FILE STATUS IS WS-FS.
       DATA DIVISION.
       FILE SECTION.
       FD  ACCOUNT-FILE.
       01  ACCT-REC.
           05  ACCT-REC-NUMBER         PIC 9(13).
           05  ACCT-REC-CUST-ID        PIC 9(10).
           05  ACCT-REC-PRODUCT-CODE   PIC 9(3).
           05  ACCT-REC-BRANCH-CODE    PIC 9(3).
           05  ACCT-REC-OPENED-DATE    PIC 9(8).
           05  ACCT-REC-CLOSED-DATE    PIC 9(8).
           05  ACCT-REC-STATUS         PIC X(1).
           05  ACCT-REC-OVERDRAFT      PIC S9(15) COMP-3.
           05  ACCT-REC-TERM-DAYS      PIC 9(4).
           05  ACCT-REC-DORMANCY-DATE  PIC 9(8).
           05  ACCT-REC-CREATED-TS     PIC 9(14).
           05  ACCT-REC-UPDATED-TS     PIC 9(14).
           05  ACCT-REC-FILLER         PIC X(16).
       WORKING-STORAGE SECTION.
       01  WS-FS PIC X(2).
       01  WS-IDX PIC 9(2).
       01  WS-DATA.
           05 FILLER PIC 9(13) VALUE 0010010099301.
           05 FILLER PIC X(1)  VALUE "A".
           05 FILLER PIC 9(13) VALUE 0010010099302.
           05 FILLER PIC X(1)  VALUE "A".
           05 FILLER PIC 9(13) VALUE 0010010099303.
           05 FILLER PIC X(1)  VALUE "C".
       01  WS-TBL REDEFINES WS-DATA.
           05 WS-E OCCURS 3 TIMES.
               10 WS-ACCT PIC 9(13).
               10 WS-ST PIC X(1).
       PROCEDURE DIVISION.
       MAIN.
           OPEN I-O ACCOUNT-FILE
           PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL WS-IDX > 3
              MOVE WS-ACCT(WS-IDX) TO ACCT-REC-NUMBER
              MOVE 9999000099 TO ACCT-REC-CUST-ID
              MOVE 001 TO ACCT-REC-PRODUCT-CODE
              MOVE 001 TO ACCT-REC-BRANCH-CODE
              MOVE 20260101 TO ACCT-REC-OPENED-DATE
              MOVE 0 TO ACCT-REC-CLOSED-DATE
              MOVE WS-ST(WS-IDX) TO ACCT-REC-STATUS
              MOVE 0 TO ACCT-REC-OVERDRAFT
              MOVE 0 TO ACCT-REC-TERM-DAYS
              MOVE 99991231 TO ACCT-REC-DORMANCY-DATE
              MOVE 20260101000000 TO ACCT-REC-CREATED-TS
              MOVE 20260101000000 TO ACCT-REC-UPDATED-TS
              MOVE SPACES TO ACCT-REC-FILLER
              WRITE ACCT-REC
                INVALID KEY REWRITE ACCT-REC INVALID KEY CONTINUE END-REWRITE
              END-WRITE
           END-PERFORM
           CLOSE ACCOUNT-FILE
           STOP RUN.
COB
cobc -x -free -W -o /tmp/fee-seed-isam /tmp/fee-seed-isam.cob 2>/dev/null || true
[ -x /tmp/fee-seed-isam ] && /tmp/fee-seed-isam || true

bash /workspace/subsystems/22-operations/src/ops-seed-system-accounts.sh > /dev/null 2>&1 || true

echo "[fee-setup-pg] done"
