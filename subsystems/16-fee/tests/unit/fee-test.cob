       IDENTIFICATION DIVISION.
       PROGRAM-ID. FEE-TEST.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  WS-N           PIC 9(3) VALUE 0.
       01  WS-P           PIC 9(3) VALUE 0.
       01  WS-F           PIC 9(3) VALUE 0.
       01  WS-TC-NUM      PIC 9(3).
       01  WS-BAL-BEFORE  PIC S9(15) COMP-3 VALUE 0.

           COPY "fee-api.cpy".

       01  WS-PATHS.
           05  WS-SUMMARY-PATH   PIC X(80) VALUE
               "/tmp/fee-test/fee-summary.dat".
           05  WS-REPORT-PATH    PIC X(80) VALUE
               "/tmp/fee-test/fee-summary.rpt".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 16-fee unit tests (Phase 5 Step 4 MVP) ==="
           PERFORM PREP-TMP
           PERFORM PREP-PG
           PERFORM TC01-HAPPY-2-POSTED
           PERFORM TC02-CAT30-NO-FEE
           PERFORM TC03-TIER1-NO-FEE
           PERFORM TC04-TIER2-POSTED
           PERFORM TC05-TIER3-POSTED
           PERFORM TC06-NSF-SKIP
           PERFORM TC07-CLOSED-SKIP
           PERFORM TC08-IDEMPOTENT-RERUN
           PERFORM TC09-HELPER-OK
           PERFORM TC10-FEE-REV-BALANCE
           PERFORM TC11-REPORT-HAPPY
           PERFORM TC12-CONSERVATION
           DISPLAY "=== Total: " WS-N
                   " | PASS: " WS-P
                   " | FAIL: " WS-F
           IF WS-F > 0
               STOP RUN RETURNING 1
           END-IF
           STOP RUN.

       PREP-TMP.
           CALL "SYSTEM" USING "mkdir -p /tmp/fee-test".

       PREP-PG.
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/16-fee/tests/unit/fee-setup-pg.sh".

       RESET-PG.
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/16-fee/tests/unit/fee-reset-pg.sh".

       CALL-FEE-CHARGE.
           MOVE "FEE-TEST-001  " TO FEE-CHARGE-BATCH-ID
           MOVE 20260613         TO FEE-CHARGE-BUSINESS-DATE
           MOVE WS-SUMMARY-PATH  TO FEE-CHARGE-SUMMARY-FILENAME
           CALL "FEE-CHARGE" USING FEE-CHARGE-INPUT FEE-CHARGE-OUTPUT.

       CALL-FEE-REPORT.
           MOVE 20260613         TO FEE-RPT-BUSINESS-DATE
           MOVE "FEE-TEST-001  " TO FEE-RPT-BATCH-ID
           MOVE WS-SUMMARY-PATH  TO FEE-RPT-SUMMARY-FILENAME
           MOVE WS-REPORT-PATH   TO FEE-RPT-REPORT-FILENAME
           CALL "FEE-REPORT-SUMMARY" USING
                FEE-REPORT-INPUT FEE-REPORT-OUTPUT.

       TC01-HAPPY-2-POSTED.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG
           PERFORM CALL-FEE-CHARGE
           IF FEE-CHARGE-OK AND FEE-OUT-CHARGES-POSTED = 2
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " 2 posts (tier 2+3)"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" FEE-CHARGE-STATUS
                       " posted=" FEE-OUT-CHARGES-POSTED
                       " scanned=" FEE-OUT-TXNS-SCANNED
                       " nofee=" FEE-OUT-SKIPPED-NO-FEE
                       " nsf=" FEE-OUT-SKIPPED-NSF
                       " closed=" FEE-OUT-SKIPPED-CLOSED
                       " total=" FEE-OUT-TOTAL-FEE-JPY
           END-IF.

       TC02-CAT30-NO-FEE.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF FEE-OUT-SKIPPED-NO-FEE >= 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat 30 skipped"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " no-fee=" FEE-OUT-SKIPPED-NO-FEE
           END-IF.

       TC03-TIER1-NO-FEE.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF FEE-OUT-SKIPPED-NO-FEE = 2
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " tier 1 zero-fee skipped"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " no-fee=" FEE-OUT-SKIPPED-NO-FEE
           END-IF.

       TC04-TIER2-POSTED.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF FEE-OUT-CHARGES-POSTED = 2
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " tier 2 posted (¥440)"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " posted=" FEE-OUT-CHARGES-POSTED
           END-IF.

       TC05-TIER3-POSTED.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF FEE-OUT-TOTAL-FEE-JPY = 1320
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " total = ¥1320 (440+880)"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " total=" FEE-OUT-TOTAL-FEE-JPY
           END-IF.

       TC06-NSF-SKIP.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF FEE-OUT-SKIPPED-NSF = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " NSF skip"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " nsf=" FEE-OUT-SKIPPED-NSF
           END-IF.

       TC07-CLOSED-SKIP.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF FEE-OUT-SKIPPED-CLOSED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " closed skip"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " closed=" FEE-OUT-SKIPPED-CLOSED
           END-IF.

       TC08-IDEMPOTENT-RERUN.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM CALL-FEE-CHARGE
           IF FEE-OUT-CHARGES-POSTED = 0 AND
              FEE-OUT-SKIPPED-ALREADY = 2
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " idempotent rerun"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " posted=" FEE-OUT-CHARGES-POSTED
                       " already=" FEE-OUT-SKIPPED-ALREADY
           END-IF.

       TC09-HELPER-OK.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF FEE-OUT-SKIPPED-HELPER = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " helper OK"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " helper rejects=" FEE-OUT-SKIPPED-HELPER
           END-IF.

       TC10-FEE-REV-BALANCE.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG
           PERFORM CALL-FEE-CHARGE
           PERFORM CALL-FEE-REPORT
           IF FEE-RPT-FEE-REVENUE-BAL = 1320
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM
                       " fee_revenue bal=¥1320"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " bal=" FEE-RPT-FEE-REVENUE-BAL
           END-IF.

       TC11-REPORT-HAPPY.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF FEE-RPT-OK AND FEE-RPT-TOTAL-CHARGES = 2
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM
                       " report 2 charges"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" FEE-RPT-STATUS
                       " charges=" FEE-RPT-TOTAL-CHARGES
           END-IF.

       TC12-CONSERVATION.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF FEE-RPT-CONSERVATION-PASS = "Y"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " conservation OK"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " conservation=" FEE-RPT-CONSERVATION-PASS
           END-IF.

       END PROGRAM FEE-TEST.
