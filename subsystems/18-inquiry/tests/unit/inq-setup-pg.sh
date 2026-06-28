#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q"

$PSQL -c "DELETE FROM balances WHERE account_number IN ('0010010099501','0010010099502','0010010099503')"
$PSQL -c "DELETE FROM accounts WHERE acct_number IN ('0010010099501','0010010099502','0010010099503')"

$PSQL -c "INSERT INTO customers (cust_id, cust_name, cust_name_kana, cust_status, tier) VALUES ('9999000098', 'INQ TEST OPERATOR', 'INQ TEST OPERATOR', 'A', 'B') ON CONFLICT (cust_id) DO NOTHING"

$PSQL -c "INSERT INTO accounts (acct_number, acct_name, branch_code, product_code, acct_status, cust_id, opened_date) VALUES
  ('0010010099501', 'INQ T1', '001', '001', 'A', '9999000098', '2026-01-01'),
  ('0010010099502', 'INQ T2', '001', '001', 'A', '9999000098', '2026-01-01'),
  ('0010010099503', 'INQ T3', '001', '001', 'C', '9999000098', '2026-01-01')
  ON CONFLICT (acct_number) DO UPDATE SET acct_status=EXCLUDED.acct_status"

$PSQL -c "INSERT INTO balances (account_number, balance_jpy, available_jpy) VALUES
  ('0010010099501', 250000, 250000),
  ('0010010099502',  75000,  75000),
  ('0010010099503',   1000,   1000)
  ON CONFLICT (account_number) DO UPDATE SET balance_jpy=EXCLUDED.balance_jpy"

cat > /tmp/inq-seed-isam.cob <<'COB'
       IDENTIFICATION DIVISION.
       PROGRAM-ID. INQ-SEED-ISAM.
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
           05 FILLER PIC 9(13) VALUE 0010010099501.
           05 FILLER PIC X(1)  VALUE "A".
           05 FILLER PIC 9(13) VALUE 0010010099502.
           05 FILLER PIC X(1)  VALUE "A".
           05 FILLER PIC 9(13) VALUE 0010010099503.
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
              MOVE 9999000098 TO ACCT-REC-CUST-ID
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
cobc -x -free -W -o /tmp/inq-seed-isam /tmp/inq-seed-isam.cob 2>/dev/null || true
[ -x /tmp/inq-seed-isam ] && /tmp/inq-seed-isam || true

echo "[inq-setup-pg] done"
