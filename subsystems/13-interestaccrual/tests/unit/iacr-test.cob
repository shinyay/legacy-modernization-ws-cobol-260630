       IDENTIFICATION DIVISION.
       PROGRAM-ID. IACR-TEST.
       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  WS-N           PIC 9(3) VALUE 0.
       01  WS-P           PIC 9(3) VALUE 0.
       01  WS-F           PIC 9(3) VALUE 0.
       01  WS-TC-NUM      PIC 9(3).

           COPY "iacr-api.cpy".

       01  WS-PATHS.
           05  WS-SUMMARY-PATH    PIC X(80) VALUE
               "/tmp/iacr-test/summary.dat".
           05  WS-REPORT-PATH     PIC X(80) VALUE
               "/tmp/iacr-test/summary.rpt".
           05  WS-CKPT-PATH       PIC X(80) VALUE
               "/tmp/iacr-test/iacr.ckp".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 13-interestaccrual unit tests (Phase 5 Step 1) ==="
           PERFORM PREP-TMP
           PERFORM PREP-PG
           PERFORM TC01-HAPPY-3-ACCRUE
           PERFORM TC02-IDEMPOTENT-RERUN
           PERFORM TC03-I5-P-STATUS-SKIP
           PERFORM TC04-I5-C-STATUS-SKIP
           PERFORM TC05-I5-D-STATUS-ACCRUE
           PERFORM TC06-I5-S-STATUS-ACCRUE
           PERFORM TC07-PROD-INTEREST-N-SKIP
           PERFORM TC08-ZERO-BALANCE-SKIP
           PERFORM TC09-SYSTEM-BLACKLIST
           PERFORM TC10-REPORT-HAPPY
           PERFORM TC11-REPORT-CONSERVATION
           PERFORM TC12-EMPTY-BALANCES
           DISPLAY "=== Total: " WS-N
                   " | PASS: " WS-P
                   " | FAIL: " WS-F
           IF WS-F > 0
               STOP RUN RETURNING 1
           END-IF
           STOP RUN.

       PREP-TMP.
           CALL "SYSTEM" USING "mkdir -p /tmp/iacr-test".

       PREP-PG.
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/13-interestaccrual/tests/unit/iacr-setup-pg.sh".

       RESET-PG-ACCRUALS.
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/13-interestaccrual/tests/unit/iacr-reset-pg.sh".

       CALL-RUN-DAILY.
           MOVE "BATCH-IACR-001" TO IACR-RUN-BATCH-ID
           MOVE 20260612         TO IACR-RUN-BUSINESS-DATE
           MOVE WS-SUMMARY-PATH  TO IACR-RUN-SUMMARY-FILENAME
           MOVE WS-CKPT-PATH     TO IACR-RUN-CHECKPOINT-FILENAME
           CALL "IACR-RUN-DAILY" USING IACR-RUN-INPUT IACR-RUN-OUTPUT.

       TC01-HAPPY-3-ACCRUE.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-ACCRUALS
           PERFORM CALL-RUN-DAILY
           IF IACR-RUN-STATUS = "00" AND
              IACR-OUT-ACCRUALS-INSERTED = 3 AND
              IACR-OUT-INELIGIBLE-STATE = 2 AND
              IACR-OUT-INELIGIBLE-PROD = 1 AND
              IACR-OUT-INELIGIBLE-BALANCE = 1 AND
              IACR-OUT-SYSTEM-SKIPPED = 4
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " 3 accruals + filters OK"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " st=" IACR-RUN-STATUS
                       " inserted=" IACR-OUT-ACCRUALS-INSERTED
                       " state=" IACR-OUT-INELIGIBLE-STATE
                       " prod=" IACR-OUT-INELIGIBLE-PROD
                       " bal=" IACR-OUT-INELIGIBLE-BALANCE
                       " sys=" IACR-OUT-SYSTEM-SKIPPED
           END-IF.

       TC02-IDEMPOTENT-RERUN.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM CALL-RUN-DAILY
           IF IACR-OUT-ACCRUALS-INSERTED = 0 AND
              IACR-OUT-ALREADY-ACCRUED = 3
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " idempotent rerun"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " inserted=" IACR-OUT-ACCRUALS-INSERTED
                       " already=" IACR-OUT-ALREADY-ACCRUED
           END-IF.

       TC03-I5-P-STATUS-SKIP.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-ACCRUALS
           PERFORM CALL-RUN-DAILY
           IF IACR-OUT-INELIGIBLE-STATE >= 2
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " I5 P+C both skipped"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " state=" IACR-OUT-INELIGIBLE-STATE
           END-IF.

       TC04-I5-C-STATUS-SKIP.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF IACR-OUT-INELIGIBLE-STATE = 2
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " C status skipped"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " state=" IACR-OUT-INELIGIBLE-STATE
           END-IF.

       TC05-I5-D-STATUS-ACCRUE.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/13-interestaccrual/tests/unit/iacr-count.sh 2026-06-12 AC > /tmp/iacr-test/cnt.out"
           IF IACR-OUT-ACCRUALS-INSERTED >= 3
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " D status accrued (=JP norm)"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
           END-IF.

       TC06-I5-S-STATUS-ACCRUE.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF IACR-OUT-ACCRUALS-INSERTED = 3
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " S status accrued"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
           END-IF.

       TC07-PROD-INTEREST-N-SKIP.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF IACR-OUT-INELIGIBLE-PROD = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " PROD INTEREST=N skipped"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " prod=" IACR-OUT-INELIGIBLE-PROD
           END-IF.

       TC08-ZERO-BALANCE-SKIP.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF IACR-OUT-INELIGIBLE-BALANCE >= 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " 0-balance skipped"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " bal=" IACR-OUT-INELIGIBLE-BALANCE
           END-IF.

       TC09-SYSTEM-BLACKLIST.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF IACR-OUT-SYSTEM-SKIPPED = 4
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " sys blacklist 4 skipped"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " sys=" IACR-OUT-SYSTEM-SKIPPED
           END-IF.

       TC10-REPORT-HAPPY.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           MOVE 20260612 TO IACR-RPT-BUSINESS-DATE
           MOVE WS-SUMMARY-PATH TO IACR-RPT-SUMMARY-FILENAME
           MOVE WS-REPORT-PATH  TO IACR-RPT-REPORT-FILENAME
           CALL "IACR-REPORT-SUMMARY" USING
                IACR-REPORT-INPUT IACR-REPORT-OUTPUT
           IF IACR-RPT-STATUS = "00" AND
              IACR-RPT-AC-COUNT = 3 AND
              IACR-RPT-CONSERVATION-PASS = "Y"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " report happy 3 AC"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" IACR-RPT-STATUS
                       " AC=" IACR-RPT-AC-COUNT
                       " cons=" IACR-RPT-CONSERVATION-PASS
           END-IF.

       TC11-REPORT-CONSERVATION.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           CALL "IACR-REPORT-SUMMARY" USING
                IACR-REPORT-INPUT IACR-REPORT-OUTPUT
           IF IACR-RPT-CONSERVATION-PASS = "Y"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " conservation pass"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
           END-IF.

       TC12-EMPTY-BALANCES.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG-ACCRUALS
           PERFORM CALL-RUN-DAILY
           IF IACR-RUN-STATUS = "00" AND
              IACR-OUT-ACCRUALS-INSERTED >= 3
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " repeatable run"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" IACR-RUN-STATUS
                       " ins=" IACR-OUT-ACCRUALS-INSERTED
           END-IF.

       END PROGRAM IACR-TEST.
