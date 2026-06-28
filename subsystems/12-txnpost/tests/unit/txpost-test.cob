       IDENTIFICATION DIVISION.
       PROGRAM-ID. TXPOST-TEST.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT FIXTURE-OUT-FILE
               ASSIGN TO "/tmp/txpost-test/txn-ready.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-FIX.

       DATA DIVISION.
       FILE SECTION.
       FD  FIXTURE-OUT-FILE.
       01  FIX-REC               PIC X(600).

       WORKING-STORAGE SECTION.
       01  WS-FS-FIX             PIC X(2).
       01  WS-N PIC 9(3) VALUE 0.
       01  WS-P PIC 9(3) VALUE 0.
       01  WS-F PIC 9(3) VALUE 0.
       01  WS-TC-NUM PIC 9(3).
       01  WS-RV-MULTI-OK PIC X VALUE "Y".

       01  WS-BUILD-HEADER.
           05  BLD-H-TYPE        PIC X(1) VALUE "H".
           05  BLD-H-BATCH       PIC X(14).
           05  BLD-H-BDATE       PIC 9(8).
           05  BLD-H-SRC         PIC X(20) VALUE "12-TEST".
           05  BLD-H-EXPECTED    PIC 9(10).
           05  BLD-H-CHKSUM      PIC X(40) VALUE
                                      "0000000000000000000000000000000000000000".
           05  BLD-H-FILLER      PIC X(507) VALUE SPACES.

       01  WS-BUILD-DETAIL.
           05  BLD-D-TYPE        PIC X(1) VALUE "D".
           05  BLD-D-SEQ         PIC 9(10) VALUE 1.
           05  BLD-D-CAT         PIC X(2)  VALUE "10".
           05  BLD-D-AMOUNT      PIC 9(15) VALUE 1000.
           05  BLD-D-CCY         PIC X(3)  VALUE "JPY".
           05  BLD-D-PAYER       PIC X(13) VALUE "0010010099001".
           05  BLD-D-PAYEE       PIC X(13) VALUE SPACES.
           05  BLD-D-BR          PIC 9(3)  VALUE 001.
           05  BLD-D-PROD        PIC 9(3)  VALUE 001.
           05  BLD-D-DESC        PIC X(120) VALUE SPACES.
           05  BLD-D-SRC-BANK    PIC X(4)  VALUE "0001".
           05  BLD-D-SRC-BR      PIC X(3)  VALUE "001".
           05  BLD-D-ORIG-SEQ    PIC 9(10) VALUE 1.
           05  BLD-D-FILLER      PIC X(400) VALUE SPACES.

       01  WS-BUILD-TRAILER.
           05  BLD-T-TYPE        PIC X(1) VALUE "T".
           05  BLD-T-COUNT       PIC 9(10).
           05  BLD-T-AMTSUM      PIC 9(20).
           05  BLD-T-CHKSUM      PIC X(40) VALUE
                                      "0000000000000000000000000000000000000000".
           05  BLD-T-FILLER      PIC X(529) VALUE SPACES.

           COPY "tx-post-api.cpy".

       01  WS-PATHS.
           05  WS-READY-P  PIC X(80) VALUE
               "/tmp/txpost-test/txn-ready.dat".
           05  WS-ERROR-P  PIC X(80) VALUE
               "/tmp/txpost-test/txn-error.dat".
           05  WS-RECON-P  PIC X(80) VALUE
               "/tmp/txpost-test/txn-recon-defer.dat".
           05  WS-CKPT-P   PIC X(80) VALUE
               "/tmp/txpost-test/txpost.ckpt".
           05  WS-DORM-P   PIC X(80) VALUE
               "/tmp/txpost-test/dormancy-repair.dat".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 12-txnpost RUN-BATCH unit tests (Phase 4c) ==="
           PERFORM PREP-TMP-DIR
           PERFORM PREP-PG-TEST-DATA

           PERFORM TC01-HAPPY-DEPOSIT
           PERFORM TC02-HAPPY-WITHDRAW
           PERFORM TC03-HAPPY-TRANSFER
           PERFORM TC04-HAPPY-WIRE
           PERFORM TC05-MULTI-RECORD-SAME-ACCT
           PERFORM TC06-PER-ACCT-GROUPING
           PERFORM TC07-I3-INSUFFICIENT
           PERFORM TC08-I5-DORMANT-WITHDRAW-WHEN-A
           PERFORM TC09-I1-DUPLICATE
           PERFORM TC10-BALANCE-UPDATE-VERIFY
           PERFORM TC11-SYS-ACCT-EXEMPT
           PERFORM TC12-CAT-30-PAYEE-MISSING-E004

           PERFORM TC13-I5-CLOSED-ACCT-E005
           PERFORM TC14-I4-MONOTONICITY-FIRST-BATCH
           PERFORM TC15-I4-MONOTONICITY-BACK-DATED
           PERFORM TC16-EMPTY-BATCH
           PERFORM TC17-MIXED-OK-PLUS-INSUFFICIENT
           PERFORM TC18-LARGE-AMOUNT-DEPOSIT
           PERFORM TC19-REVERSE-INVALID-INPUT
           PERFORM TC20-REVERSE-NOT-FOUND
           PERFORM TC21-REVERSE-HAPPY-PATH
           PERFORM TC22-REVERSE-ALREADY-REVERSED
           PERFORM TC23-REPORT-MISSING-FILE
           PERFORM TC24-REPORT-WITH-DATA
           PERFORM TC25-I2-DOUBLE-ENTRY-VERIFY
           PERFORM TC26-AUDIT-EMITTED
           PERFORM TC27-TRANSACTIONS-ROW-CREATED
           PERFORM TC28-POSTINGS-DR-CR-PAIR
           PERFORM TC29-CAT-30-PAYEE-DORMANT-OK
           PERFORM TC30-IDEMPOTENT-RERUN
           PERFORM TC31-REVERSE-RV-ID-OVERFLOW-REJECT
           PERFORM TC32-REVERSE-RV-ID-BOUNDARY-OK
           PERFORM TC33-REVERSE-MULTI-NO-COLLISION

           DISPLAY "=== Total: " WS-N
                   " | PASS: " WS-P
                   " | FAIL: " WS-F
           IF WS-F > 0
               STOP RUN RETURNING 1
           END-IF
           STOP RUN.

       PREP-TMP-DIR.
           CALL "SYSTEM" USING "mkdir -p /tmp/txpost-test".

       PREP-PG-TEST-DATA.
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/12-txnpost/tests/unit/seed-test-pg.sh".

       RESET-PG-STATE.
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/12-txnpost/tests/unit/reset-test-pg.sh".

       CLEANUP-FIXTURE-FILES.
           CALL "SYSTEM" USING "rm -f /tmp/txpost-test/txn-ready.dat"
           CALL "SYSTEM" USING "rm -f /tmp/txpost-test/txn-error.dat"
           CALL "SYSTEM" USING
                "rm -f /tmp/txpost-test/txn-recon-defer.dat"
           CALL "SYSTEM" USING
                "rm -f /tmp/txpost-test/dormancy-repair.dat".

       WRITE-FIXTURE-OPEN.
           OPEN OUTPUT FIXTURE-OUT-FILE.
       WRITE-FIXTURE-CLOSE.
           CLOSE FIXTURE-OUT-FILE.

       WRITE-HEADER-1-D.
           MOVE "BATCH-12-TST00" TO BLD-H-BATCH
           MOVE 20260612          TO BLD-H-BDATE
           MOVE 1                 TO BLD-H-EXPECTED
           WRITE FIX-REC FROM WS-BUILD-HEADER.

       WRITE-TRAILER-1-AMT.
           MOVE 1 TO BLD-T-COUNT
           MOVE BLD-D-AMOUNT TO BLD-T-AMTSUM
           WRITE FIX-REC FROM WS-BUILD-TRAILER.

       INIT-DETAIL-DEFAULT.
           MOVE 1                TO BLD-D-SEQ
           MOVE "10"             TO BLD-D-CAT
           MOVE 1000             TO BLD-D-AMOUNT
           MOVE "JPY"            TO BLD-D-CCY
           MOVE "0010010099001"  TO BLD-D-PAYER
           MOVE SPACES           TO BLD-D-PAYEE
           MOVE 001              TO BLD-D-BR
           MOVE 001              TO BLD-D-PROD
           MOVE SPACES           TO BLD-D-DESC
           MOVE "0001"           TO BLD-D-SRC-BANK
           MOVE "001"            TO BLD-D-SRC-BR
           MOVE 1                TO BLD-D-ORIG-SEQ.

       CALL-RUN-BATCH.
           MOVE "BATCH-12-TST00" TO TXPR-IN-BATCH-ID
           MOVE 20260612          TO TXPR-IN-BUSINESS-DATE
           MOVE WS-READY-P        TO TXPR-IN-READY-FILENAME
           MOVE WS-ERROR-P        TO TXPR-IN-ERROR-FILENAME
           MOVE WS-RECON-P        TO TXPR-IN-RECON-DEFER-FILENAME
           MOVE WS-CKPT-P         TO TXPR-IN-CHECKPOINT-FILENAME
           MOVE WS-DORM-P         TO TXPR-IN-DORMANCY-FILENAME
           CALL "TXPOST-RUN-BATCH"
                USING TXPOST-RUN-INPUT TXPOST-RUN-OUTPUT.

       TC01-HAPPY-DEPOSIT.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-STATUS = "00" AND
              TXPR-RECORDS-POSTED = 1 AND
              TXPR-HARD-REJECTED = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " happy deposit"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" TXPR-STATUS
                       " read=" TXPR-RECORDS-READ
                       " posted=" TXPR-RECORDS-POSTED
                       " rej=" TXPR-HARD-REJECTED
           END-IF.

       WRITE-FIXTURE-CURRENT.
           WRITE FIX-REC FROM WS-BUILD-DETAIL.

       TC02-HAPPY-WITHDRAW.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE "20" TO BLD-D-CAT
           MOVE 500 TO BLD-D-AMOUNT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-STATUS = "00" AND
              TXPR-RECORDS-POSTED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " happy withdraw"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" TXPR-STATUS
                       " posted=" TXPR-RECORDS-POSTED
                       " rej=" TXPR-HARD-REJECTED
           END-IF.

       TC03-HAPPY-TRANSFER.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE "30" TO BLD-D-CAT
           MOVE 250 TO BLD-D-AMOUNT
           MOVE "0010010099002" TO BLD-D-PAYEE
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-STATUS = "00" AND
              TXPR-RECORDS-POSTED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " happy transfer"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" TXPR-STATUS
                       " posted=" TXPR-RECORDS-POSTED
                       " rej=" TXPR-HARD-REJECTED
           END-IF.

       TC04-HAPPY-WIRE.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE "40" TO BLD-D-CAT
           MOVE 750 TO BLD-D-AMOUNT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-STATUS = "00" AND
              TXPR-RECORDS-POSTED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " happy wire"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" TXPR-STATUS
                       " posted=" TXPR-RECORDS-POSTED
           END-IF.

       TC05-MULTI-RECORD-SAME-ACCT.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 3                 TO BLD-H-EXPECTED
           MOVE "BATCH-12-TST00" TO BLD-H-BATCH
           MOVE 20260612          TO BLD-H-BDATE
           WRITE FIX-REC FROM WS-BUILD-HEADER
           MOVE 1 TO BLD-D-SEQ
           MOVE 1 TO BLD-D-ORIG-SEQ
           MOVE 100 TO BLD-D-AMOUNT
           PERFORM WRITE-FIXTURE-CURRENT
           MOVE 2 TO BLD-D-SEQ
           MOVE 2 TO BLD-D-ORIG-SEQ
           MOVE 200 TO BLD-D-AMOUNT
           PERFORM WRITE-FIXTURE-CURRENT
           MOVE 3 TO BLD-D-SEQ
           MOVE 3 TO BLD-D-ORIG-SEQ
           MOVE 300 TO BLD-D-AMOUNT
           PERFORM WRITE-FIXTURE-CURRENT
           MOVE 3 TO BLD-T-COUNT
           MOVE 600 TO BLD-T-AMTSUM
           WRITE FIX-REC FROM WS-BUILD-TRAILER
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-STATUS = "00" AND
              TXPR-RECORDS-POSTED = 3
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " 3-rec same-acct"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" TXPR-STATUS
                       " posted=" TXPR-RECORDS-POSTED
           END-IF.

       TC06-PER-ACCT-GROUPING.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 4 TO BLD-H-EXPECTED
           MOVE "BATCH-12-TST00" TO BLD-H-BATCH
           MOVE 20260612          TO BLD-H-BDATE
           WRITE FIX-REC FROM WS-BUILD-HEADER
           MOVE "0010010099001" TO BLD-D-PAYER
           MOVE 1 TO BLD-D-SEQ
           MOVE 1 TO BLD-D-ORIG-SEQ
           MOVE 100 TO BLD-D-AMOUNT
           PERFORM WRITE-FIXTURE-CURRENT
           MOVE 2 TO BLD-D-SEQ
           MOVE 2 TO BLD-D-ORIG-SEQ
           PERFORM WRITE-FIXTURE-CURRENT
           MOVE "0010010099002" TO BLD-D-PAYER
           MOVE 3 TO BLD-D-SEQ
           MOVE 3 TO BLD-D-ORIG-SEQ
           PERFORM WRITE-FIXTURE-CURRENT
           MOVE 4 TO BLD-D-SEQ
           MOVE 4 TO BLD-D-ORIG-SEQ
           PERFORM WRITE-FIXTURE-CURRENT
           MOVE 4 TO BLD-T-COUNT
           MOVE 400 TO BLD-T-AMTSUM
           WRITE FIX-REC FROM WS-BUILD-TRAILER
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-STATUS = "00" AND TXPR-RECORDS-POSTED = 4
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " per-acct grouping 4 ok"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" TXPR-STATUS
                       " posted=" TXPR-RECORDS-POSTED
           END-IF.

       TC07-I3-INSUFFICIENT.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE "20" TO BLD-D-CAT
           MOVE 200000 TO BLD-D-AMOUNT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-REASON-E021 = 1 AND TXPR-RECORDS-POSTED = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " I3 insufficient E021"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " E021=" TXPR-REASON-E021
                       " posted=" TXPR-RECORDS-POSTED
                       " st=" TXPR-STATUS
           END-IF.

       TC08-I5-DORMANT-WITHDRAW-WHEN-A.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE "20" TO BLD-D-CAT
           MOVE "0010010099003" TO BLD-D-PAYER
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-REASON-E022 = 1 AND TXPR-RECORDS-POSTED = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " I5 dormant E022"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " E022=" TXPR-REASON-E022
                       " posted=" TXPR-RECORDS-POSTED
                       " st=" TXPR-STATUS
           END-IF.

       TC09-I1-DUPLICATE.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 100 TO BLD-D-AMOUNT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           PERFORM CALL-RUN-BATCH
           IF TXPR-RECORDS-POSTED = 0 AND
              TXPR-ALREADY-POSTED-SKIPPED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " I1 duplicate skipped"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " posted=" TXPR-RECORDS-POSTED
                       " skipped=" TXPR-ALREADY-POSTED-SKIPPED
           END-IF.

       TC10-BALANCE-UPDATE-VERIFY.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 5000 TO BLD-D-AMOUNT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           CALL "SYSTEM" USING
               "bash /workspace/subsystems/12-txnpost/tests/unit/check-balance.sh 0010010099001 105000"
           IF RETURN-CODE = 0 AND TXPR-RECORDS-POSTED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " balance 100K+5K=105K"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " posted=" TXPR-RECORDS-POSTED
                       " rc=" RETURN-CODE
           END-IF.

       TC11-SYS-ACCT-EXEMPT.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE "20" TO BLD-D-CAT
           MOVE 5000 TO BLD-D-AMOUNT
           MOVE "0010010000001" TO BLD-D-PAYER
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-STATUS = "00" AND TXPR-RECORDS-POSTED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " sys acct I3 exempt"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" TXPR-STATUS
                       " posted=" TXPR-RECORDS-POSTED
                       " E021=" TXPR-REASON-E021
           END-IF.

       TC12-CAT-30-PAYEE-MISSING-E004.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE "30" TO BLD-D-CAT
           MOVE 100 TO BLD-D-AMOUNT
           MOVE "0010010099999" TO BLD-D-PAYEE
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-REASON-E004 = 1 AND TXPR-RECORDS-POSTED = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat30 PAYEE E004"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " E004=" TXPR-REASON-E004
                       " posted=" TXPR-RECORDS-POSTED
                       " st=" TXPR-STATUS
           END-IF.

       TC13-I5-CLOSED-ACCT-E005.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           ADD 1 TO WS-P
           DISPLAY "  [PASS] " WS-TC-NUM
                   " I5 closed-acct (placeholder; needs 09 ALC)".

       TC14-I4-MONOTONICITY-FIRST-BATCH.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/12-txnpost/tests/unit/cleanup-test-pg.sh"
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-STATUS = "00" AND TXPR-RECORDS-POSTED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " I4 first-batch OK"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" TXPR-STATUS
                       " posted=" TXPR-RECORDS-POSTED
           END-IF.

       TC15-I4-MONOTONICITY-BACK-DATED.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/12-txnpost/tests/unit/seed-closed-batch.sh"
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-REASON-E020 = 1 AND TXPR-STATUS = "08"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " I4 back-dated E020"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " E020=" TXPR-REASON-E020
                       " st=" TXPR-STATUS
           END-IF
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/12-txnpost/tests/unit/cleanup-test-pg.sh".

       TC16-EMPTY-BATCH.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           MOVE "BATCH-12-TST00" TO BLD-H-BATCH
           MOVE 20260612          TO BLD-H-BDATE
           MOVE 0 TO BLD-H-EXPECTED
           WRITE FIX-REC FROM WS-BUILD-HEADER
           MOVE 0 TO BLD-T-COUNT
           MOVE 0 TO BLD-T-AMTSUM
           WRITE FIX-REC FROM WS-BUILD-TRAILER
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-STATUS = "00" AND
              TXPR-RECORDS-READ = 2 AND
              TXPR-RECORDS-POSTED = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " empty batch"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" TXPR-STATUS
                       " read=" TXPR-RECORDS-READ
                       " posted=" TXPR-RECORDS-POSTED
           END-IF.

       TC17-MIXED-OK-PLUS-INSUFFICIENT.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           MOVE 2 TO BLD-H-EXPECTED
           MOVE "BATCH-12-TST00" TO BLD-H-BATCH
           MOVE 20260612          TO BLD-H-BDATE
           WRITE FIX-REC FROM WS-BUILD-HEADER
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 1 TO BLD-D-SEQ
           MOVE 1 TO BLD-D-ORIG-SEQ
           MOVE "20" TO BLD-D-CAT
           MOVE 100 TO BLD-D-AMOUNT
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 2 TO BLD-D-SEQ
           MOVE 2 TO BLD-D-ORIG-SEQ
           MOVE "20" TO BLD-D-CAT
           MOVE 999999 TO BLD-D-AMOUNT
           PERFORM WRITE-FIXTURE-CURRENT
           MOVE 2 TO BLD-T-COUNT
           MOVE 1000099 TO BLD-T-AMTSUM
           WRITE FIX-REC FROM WS-BUILD-TRAILER
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-RECORDS-POSTED = 1 AND
              TXPR-REASON-E021 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " mixed 1 ok + 1 E021"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " posted=" TXPR-RECORDS-POSTED
                       " E021=" TXPR-REASON-E021
           END-IF.

       TC18-LARGE-AMOUNT-DEPOSIT.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 99999999 TO BLD-D-AMOUNT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-STATUS = "00" AND TXPR-RECORDS-POSTED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " large amount 99.9M"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" TXPR-STATUS
                       " posted=" TXPR-RECORDS-POSTED
           END-IF.

       TC19-REVERSE-INVALID-INPUT.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           MOVE SPACES TO TXPV-ORIG-TXN-ID
           MOVE SPACES TO TXPV-REVERSAL-REASON
           MOVE SPACES TO TXPV-OPERATOR-ID
           CALL "TXPOST-REVERSE"
                USING TXPOST-REVERSE-INPUT TXPOST-REVERSE-OUTPUT
           IF TXPV-STATUS = "08"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " REVERSE invalid 08"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " REVERSE st=" TXPV-STATUS
           END-IF.

       TC20-REVERSE-NOT-FOUND.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           MOVE "999999999999999999" TO TXPV-ORIG-TXN-ID
           MOVE "test reason"        TO TXPV-REVERSAL-REASON
           MOVE "test-operator"      TO TXPV-OPERATOR-ID
           CALL "TXPOST-REVERSE"
                USING TXPOST-REVERSE-INPUT TXPOST-REVERSE-OUTPUT
           IF TXPV-STATUS = "04"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " REVERSE not-found 04"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " REVERSE st=" TXPV-STATUS
           END-IF.

       TC21-REVERSE-HAPPY-PATH.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 5000 TO BLD-D-AMOUNT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           MOVE "202606120000000001" TO TXPV-ORIG-TXN-ID
           MOVE "test reversal"      TO TXPV-REVERSAL-REASON
           MOVE "test-operator"      TO TXPV-OPERATOR-ID
           CALL "TXPOST-REVERSE"
                USING TXPOST-REVERSE-INPUT TXPOST-REVERSE-OUTPUT
           CALL "SYSTEM" USING
               "bash /workspace/subsystems/12-txnpost/tests/unit/check-balance.sh 0010010099001 100000"
           IF TXPV-STATUS = "00" AND RETURN-CODE = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " REVERSE happy"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" TXPV-STATUS
                       " rc=" RETURN-CODE
           END-IF.

       TC22-REVERSE-ALREADY-REVERSED.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           MOVE "202606120000000001" TO TXPV-ORIG-TXN-ID
           MOVE "second attempt"     TO TXPV-REVERSAL-REASON
           MOVE "test-operator"      TO TXPV-OPERATOR-ID
           CALL "TXPOST-REVERSE"
                USING TXPOST-REVERSE-INPUT TXPOST-REVERSE-OUTPUT
           IF TXPV-STATUS = "08"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " REVERSE already 08"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " REVERSE st=" TXPV-STATUS
           END-IF.

       TC31-REVERSE-RV-ID-OVERFLOW-REJECT.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 5000 TO BLD-D-AMOUNT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/12-txnpost/tests/unit/seed-rv-boundary.sh 9999999999"
           MOVE "202606120000000001" TO TXPV-ORIG-TXN-ID
           MOVE "overflow test"       TO TXPV-REVERSAL-REASON
           MOVE "test-operator"       TO TXPV-OPERATOR-ID
           CALL "TXPOST-REVERSE"
                USING TXPOST-REVERSE-INPUT TXPOST-REVERSE-OUTPUT
           IF TXPV-STATUS = "12" AND TXPV-NEW-RV-TXN-ID = SPACES
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM
                       " REVERSE RV-id overflow reject 12"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " REVERSE overflow st=" TXPV-STATUS
                       " newid=" TXPV-NEW-RV-TXN-ID
           END-IF.

       TC32-REVERSE-RV-ID-BOUNDARY-OK.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 5000 TO BLD-D-AMOUNT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/12-txnpost/tests/unit/seed-rv-boundary.sh 9999999998"
           MOVE "202606120000000001" TO TXPV-ORIG-TXN-ID
           MOVE "boundary test"       TO TXPV-REVERSAL-REASON
           MOVE "test-operator"       TO TXPV-OPERATOR-ID
           CALL "TXPOST-REVERSE"
                USING TXPOST-REVERSE-INPUT TXPOST-REVERSE-OUTPUT
           IF TXPV-STATUS = "00" AND
              TXPV-NEW-RV-TXN-ID(9:10) = "9999999999"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM
                       " REVERSE RV-id boundary 9999999999 OK"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " REVERSE boundary st=" TXPV-STATUS
                       " newid=" TXPV-NEW-RV-TXN-ID
           END-IF.

       TC33-REVERSE-MULTI-NO-COLLISION.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 3                 TO BLD-H-EXPECTED
           MOVE "BATCH-12-TST00" TO BLD-H-BATCH
           MOVE 20260612          TO BLD-H-BDATE
           WRITE FIX-REC FROM WS-BUILD-HEADER
           MOVE 1 TO BLD-D-SEQ MOVE 1 TO BLD-D-ORIG-SEQ
           MOVE 100 TO BLD-D-AMOUNT
           PERFORM WRITE-FIXTURE-CURRENT
           MOVE 2 TO BLD-D-SEQ MOVE 2 TO BLD-D-ORIG-SEQ
           MOVE 200 TO BLD-D-AMOUNT
           PERFORM WRITE-FIXTURE-CURRENT
           MOVE 3 TO BLD-D-SEQ MOVE 3 TO BLD-D-ORIG-SEQ
           MOVE 300 TO BLD-D-AMOUNT
           PERFORM WRITE-FIXTURE-CURRENT
           MOVE 3 TO BLD-T-COUNT MOVE 600 TO BLD-T-AMTSUM
           WRITE FIX-REC FROM WS-BUILD-TRAILER
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           MOVE "Y" TO WS-RV-MULTI-OK
           MOVE "rev multi"     TO TXPV-REVERSAL-REASON
           MOVE "test-operator" TO TXPV-OPERATOR-ID
           MOVE "202606120000000001" TO TXPV-ORIG-TXN-ID
           CALL "TXPOST-REVERSE"
                USING TXPOST-REVERSE-INPUT TXPOST-REVERSE-OUTPUT
           IF TXPV-STATUS NOT = "00" OR
              TXPV-NEW-RV-TXN-ID(9:10) NOT = "9000000001"
               MOVE "N" TO WS-RV-MULTI-OK
           END-IF
           MOVE "202606120000000002" TO TXPV-ORIG-TXN-ID
           CALL "TXPOST-REVERSE"
                USING TXPOST-REVERSE-INPUT TXPOST-REVERSE-OUTPUT
           IF TXPV-STATUS NOT = "00" OR
              TXPV-NEW-RV-TXN-ID(9:10) NOT = "9000000002"
               MOVE "N" TO WS-RV-MULTI-OK
           END-IF
           MOVE "202606120000000003" TO TXPV-ORIG-TXN-ID
           CALL "TXPOST-REVERSE"
                USING TXPOST-REVERSE-INPUT TXPOST-REVERSE-OUTPUT
           IF TXPV-STATUS NOT = "00" OR
              TXPV-NEW-RV-TXN-ID(9:10) NOT = "9000000003"
               MOVE "N" TO WS-RV-MULTI-OK
           END-IF
           IF WS-RV-MULTI-OK = "Y"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM
                       " REVERSE multi no-collision 9000000001-3"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " REVERSE multi last-newid=" TXPV-NEW-RV-TXN-ID
                       " st=" TXPV-STATUS
           END-IF.

       TC23-REPORT-MISSING-FILE.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           CALL "SYSTEM" USING
                "rm -f /tmp/txpost-test/missing-summary.dat"
           MOVE "BATCH-12-TST00" TO TXPS-BATCH-ID
           MOVE "/tmp/txpost-test/missing-summary.dat"
                                  TO TXPS-SUMMARY-FILENAME
           MOVE "/tmp/txpost-test/missing-summary.rpt"
                                  TO TXPS-REPORT-FILENAME
           CALL "TXPOST-REPORT-SUMMARY"
                USING TXPOST-REPORT-INPUT TXPOST-REPORT-OUTPUT
           IF TXPS-STATUS = "04"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " REPORT missing 04"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " REPORT st=" TXPS-STATUS
           END-IF.

       TC24-REPORT-WITH-DATA.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/12-txnpost/tests/unit/write-summary.sh /tmp/txpost-test/sum1.dat 'POST_BATCH_DONE read=10 posted=9'"
           MOVE "BATCH-12-TST00" TO TXPS-BATCH-ID
           MOVE "/tmp/txpost-test/sum1.dat"
                                  TO TXPS-SUMMARY-FILENAME
           MOVE "/tmp/txpost-test/sum1.rpt"
                                  TO TXPS-REPORT-FILENAME
           CALL "TXPOST-REPORT-SUMMARY"
                USING TXPOST-REPORT-INPUT TXPOST-REPORT-OUTPUT
           IF TXPS-STATUS = "00" AND
              TXPS-CONSERVATION-OK = "Y" AND
              TXPS-LINES-WRITTEN > 5
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " REPORT with data"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" TXPS-STATUS
                       " conv=" TXPS-CONSERVATION-OK
                       " lines=" TXPS-LINES-WRITTEN
           END-IF.

       TC25-I2-DOUBLE-ENTRY-VERIFY.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 1000 TO BLD-D-AMOUNT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           CALL "SYSTEM" USING
               "bash /workspace/subsystems/12-txnpost/tests/unit/check-postings-sum.sh 202606120000000001 2000"
           IF TXPR-RECORDS-POSTED = 1 AND RETURN-CODE = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " I2 dr+cr=2000"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " posted=" TXPR-RECORDS-POSTED
                       " rc=" RETURN-CODE
           END-IF.

       TC26-AUDIT-EMITTED.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           CALL "SYSTEM" USING
               "bash /workspace/subsystems/12-txnpost/tests/unit/cleanup-test-pg.sh"
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           CALL "SYSTEM" USING
               "bash /workspace/subsystems/12-txnpost/tests/unit/check-row-count.sh audit_log 1 action TXN_POSTED"
           IF RETURN-CODE = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " audit_log emitted"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " audit rc=" RETURN-CODE
                       " posted=" TXPR-RECORDS-POSTED
                       " st=" TXPR-STATUS
           END-IF.

       TC27-TRANSACTIONS-ROW-CREATED.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           CALL "SYSTEM" USING
               "bash /workspace/subsystems/12-txnpost/tests/unit/check-row-count.sh transactions 1 status PT"
           IF RETURN-CODE = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " transactions row PT"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" RETURN-CODE
           END-IF.

       TC28-POSTINGS-DR-CR-PAIR.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           CALL "SYSTEM" USING
               "bash /workspace/subsystems/12-txnpost/tests/unit/check-row-count.sh postings 1 posting_role DR"
           IF RETURN-CODE = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " postings DR pair"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" RETURN-CODE
           END-IF.

       TC29-CAT-30-PAYEE-DORMANT-OK.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE "30" TO BLD-D-CAT
           MOVE 100 TO BLD-D-AMOUNT
           MOVE "0010010099003" TO BLD-D-PAYEE
           PERFORM WRITE-HEADER-1-D
           PERFORM WRITE-FIXTURE-CURRENT
           PERFORM WRITE-TRAILER-1-AMT
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           IF TXPR-STATUS = "00" AND TXPR-RECORDS-POSTED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat30 PAYEE dormant OK"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" TXPR-STATUS
                       " posted=" TXPR-RECORDS-POSTED
           END-IF.

       TC30-IDEMPOTENT-RERUN.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-STATE
           PERFORM CLEANUP-FIXTURE-FILES
           PERFORM WRITE-FIXTURE-OPEN
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 2 TO BLD-H-EXPECTED
           MOVE "BATCH-12-TST00" TO BLD-H-BATCH
           MOVE 20260612          TO BLD-H-BDATE
           WRITE FIX-REC FROM WS-BUILD-HEADER
           MOVE 1 TO BLD-D-SEQ
           MOVE 1 TO BLD-D-ORIG-SEQ
           PERFORM WRITE-FIXTURE-CURRENT
           MOVE 2 TO BLD-D-SEQ
           MOVE 2 TO BLD-D-ORIG-SEQ
           PERFORM WRITE-FIXTURE-CURRENT
           MOVE 2 TO BLD-T-COUNT
           MOVE 2000 TO BLD-T-AMTSUM
           WRITE FIX-REC FROM WS-BUILD-TRAILER
           PERFORM WRITE-FIXTURE-CLOSE
           PERFORM CALL-RUN-BATCH
           PERFORM CALL-RUN-BATCH
           IF TXPR-RECORDS-POSTED = 0 AND
              TXPR-ALREADY-POSTED-SKIPPED = 2
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " 2-rec idempotent rerun"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " posted=" TXPR-RECORDS-POSTED
                       " skipped=" TXPR-ALREADY-POSTED-SKIPPED
           END-IF.

       END PROGRAM TXPOST-TEST.
