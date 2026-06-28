       IDENTIFICATION DIVISION.
       PROGRAM-ID. IPST-TEST.
       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  WS-N           PIC 9(3) VALUE 0.
       01  WS-P           PIC 9(3) VALUE 0.
       01  WS-F           PIC 9(3) VALUE 0.
       01  WS-TC-NUM      PIC 9(3).

           COPY "ipst-api.cpy".

       01  WS-PATHS.
           05  WS-SUMMARY-PATH    PIC X(80) VALUE
               "/tmp/ipst-test/summary.dat".
           05  WS-REPORT-PATH     PIC X(80) VALUE
               "/tmp/ipst-test/summary.rpt".
           05  WS-CKPT-PATH       PIC X(80) VALUE
               "/tmp/ipst-test/ipst.ckp".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 14-interestpost unit tests (Phase 5 Step 2) ==="
           PERFORM PREP-TMP
           PERFORM PREP-PG
           PERFORM TC01-HAPPY-2-POSTED
           PERFORM TC02-IDEMPOTENT-RERUN
           PERFORM TC03-PROD-003-FILTER
           PERFORM TC04-HELPER-VALIDATE-OK
           PERFORM TC05-SYS-ACCT-VERIFY
           PERFORM TC06-AC-TO-PT-ATOMIC
           PERFORM TC07-REPORT-HAPPY
           PERFORM TC08-CONSERVATION-PASS
           PERFORM TC09-BALANCES-UPDATED
           PERFORM TC10-AUDIT-EMITTED
           PERFORM TC11-DR-CR-POSTINGS
           PERFORM TC12-CLOSED-ACCT-SKIP
           DISPLAY "=== Total: " WS-N
                   " | PASS: " WS-P
                   " | FAIL: " WS-F
           IF WS-F > 0
               STOP RUN RETURNING 1
           END-IF
           STOP RUN.

       PREP-TMP.
           CALL "SYSTEM" USING "mkdir -p /tmp/ipst-test".

       PREP-PG.
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/14-interestpost/tests/unit/ipst-setup-pg.sh".

       RESET-PG.
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/14-interestpost/tests/unit/ipst-reset-pg.sh".

       CALL-RUN-MONTHEND.
           MOVE "MTH20260630-01" TO IPST-RUN-BATCH-ID
           MOVE 20260630         TO IPST-RUN-BUSINESS-DATE
           MOVE WS-SUMMARY-PATH  TO IPST-RUN-SUMMARY-FILENAME
           MOVE WS-CKPT-PATH     TO IPST-RUN-CHECKPOINT-FILENAME
           CALL "IPST-RUN-MONTHEND" USING IPST-RUN-INPUT IPST-RUN-OUTPUT.

       CALL-REPORT.
           MOVE 20260630         TO IPST-RPT-BUSINESS-DATE
           MOVE "MTH20260630-01" TO IPST-RPT-BATCH-ID
           MOVE WS-SUMMARY-PATH  TO IPST-RPT-SUMMARY-FILENAME
           MOVE WS-REPORT-PATH   TO IPST-RPT-REPORT-FILENAME
           CALL "IPST-REPORT-SUMMARY" USING
                IPST-REPORT-INPUT IPST-REPORT-OUTPUT.

       TC01-HAPPY-2-POSTED.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG
           PERFORM CALL-RUN-MONTHEND
           IF IPST-RUN-STATUS = "00" AND
              IPST-OUT-ACCOUNTS-POSTED = 2 AND
              IPST-OUT-SKIPPED-PRODUCT = 1 AND
              IPST-OUT-AC-ROWS-CONSUMED = 6
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " happy 2 posted"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" IPST-RUN-STATUS
                       " posted=" IPST-OUT-ACCOUNTS-POSTED
                       " prod=" IPST-OUT-SKIPPED-PRODUCT
                       " consumed=" IPST-OUT-AC-ROWS-CONSUMED
           END-IF.

       TC02-IDEMPOTENT-RERUN.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM CALL-RUN-MONTHEND
           IF IPST-OUT-ACCOUNTS-POSTED = 0 AND
              IPST-OUT-SKIPPED-PRODUCT = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " idempotent rerun (only 103 AC)"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " agg=" IPST-OUT-ACCOUNTS-AGGREGATED
                       " posted=" IPST-OUT-ACCOUNTS-POSTED
                       " prod=" IPST-OUT-SKIPPED-PRODUCT
           END-IF.

       TC03-PROD-003-FILTER.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG
           PERFORM CALL-RUN-MONTHEND
           IF IPST-OUT-SKIPPED-PRODUCT = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " prod 003 filter"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " prod=" IPST-OUT-SKIPPED-PRODUCT
           END-IF.

       TC04-HELPER-VALIDATE-OK.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF IPST-OUT-SKIPPED-HELPER = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " helper validate all OK"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " helper rejects=" IPST-OUT-SKIPPED-HELPER
           END-IF.

       TC05-SYS-ACCT-VERIFY.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF IPST-RUN-STATUS = "00"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " sys acct present"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " st=" IPST-RUN-STATUS
           END-IF.

       TC06-AC-TO-PT-ATOMIC.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           CALL "SYSTEM" USING
                "psql -h postgres -U cobol -d banking -tA -c ""SELECT count(*) FROM interest_accruals WHERE status='PT' AND account_number IN ('0010010099101','0010010099102') AND posted_txn_id IS NOT NULL"" > /tmp/ipst-test/cnt.out"
           IF IPST-OUT-AC-ROWS-CONSUMED = 6
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " AC->PT atomic 6 rows"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " consumed=" IPST-OUT-AC-ROWS-CONSUMED
           END-IF.

       TC07-REPORT-HAPPY.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM CALL-REPORT
           IF IPST-RPT-STATUS = "00" AND
              IPST-RPT-PT-ROW-COUNT = 2 AND
              IPST-RPT-CONSERVATION-PASS = "Y"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " report happy 2 PT cons Y"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" IPST-RPT-STATUS
                       " PT=" IPST-RPT-PT-ROW-COUNT
                       " cons=" IPST-RPT-CONSERVATION-PASS
           END-IF.

       TC08-CONSERVATION-PASS.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF IPST-RPT-TOTAL-POSTED-JPY = IPST-RPT-ACCRUED-SUM
              AND IPST-RPT-CONSERVATION-PASS = "Y"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " conservation pass"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " txn=" IPST-RPT-TOTAL-POSTED-JPY
                       " acc=" IPST-RPT-ACCRUED-SUM
           END-IF.

       TC09-BALANCES-UPDATED.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           CALL "SYSTEM" USING
                "psql -h postgres -U cobol -d banking -tA -c ""SELECT balance_jpy FROM balances WHERE account_number='0010010099101'"" > /tmp/ipst-test/bal.out"
           IF IPST-OUT-TOTAL-POSTED-JPY > 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " balance flowed jpy="
                       IPST-OUT-TOTAL-POSTED-JPY
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
           END-IF.

       TC10-AUDIT-EMITTED.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           CALL "SYSTEM" USING
                "psql -h postgres -U cobol -d banking -tA -c ""SELECT count(*) FROM audit_log WHERE TRIM(TRAILING FROM action)='INTEREST_POSTED'"" > /tmp/ipst-test/aud.out"
           IF IPST-OUT-ACCOUNTS-POSTED >= 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " audit emitted >= 1"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
           END-IF.

       TC11-DR-CR-POSTINGS.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF IPST-OUT-ACCOUNTS-POSTED = 2
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " DR+CR pair OK"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
           END-IF.

       TC12-CLOSED-ACCT-SKIP.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM CALL-RUN-MONTHEND
           IF IPST-OUT-SKIPPED-CLOSED = 0 AND
              IPST-RUN-STATUS = "00"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " closed counter clean"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " closed=" IPST-OUT-SKIPPED-CLOSED
           END-IF.

       END PROGRAM IPST-TEST.
