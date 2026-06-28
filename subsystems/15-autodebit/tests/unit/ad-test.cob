       IDENTIFICATION DIVISION.
       PROGRAM-ID. AD-TEST.
       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  WS-N           PIC 9(3) VALUE 0.
       01  WS-P           PIC 9(3) VALUE 0.
       01  WS-F           PIC 9(3) VALUE 0.
       01  WS-TC-NUM      PIC 9(3).

           COPY "ad-api.cpy".

       01  WS-PATHS.
           05  WS-FAILED-PATH    PIC X(80) VALUE
               "/tmp/ad-test/autodebit-failed.dat".
           05  WS-CKPT-PATH      PIC X(80) VALUE
               "/tmp/ad-test/ad.ckp".
           05  WS-SUMMARY-PATH   PIC X(80) VALUE
               "/tmp/ad-test/summary.dat".
           05  WS-REPORT-PATH    PIC X(80) VALUE
               "/tmp/ad-test/summary.rpt".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 15-autodebit unit tests (Phase 5 Step 3) ==="
           PERFORM PREP-TMP
           PERFORM PREP-PG
           PERFORM TC01-HAPPY-1-POSTED
           PERFORM TC02-INSUFFICIENT-FUNDS
           PERFORM TC03-DORMANT-ACCT
           PERFORM TC04-CLOSED-ACCT
           PERFORM TC05-IDEMPOTENT-RERUN
           PERFORM TC06-FAILED-FILE-WRITTEN
           PERFORM TC07-HELPER-VALIDATE-OK
           PERFORM TC08-AUTO-TM-CLOSED
           PERFORM TC09-RETRY-FSM-CAP3
           PERFORM TC10-FREQUENCY-ADVANCE
           PERFORM TC11-REPORT-HAPPY
           PERFORM TC12-DECLARATIVES-PRESENT
           PERFORM TC13-MULTI-INSTR-SAME-PAYER
           PERFORM TC14-IDEMPOTENT-PER-INSTRUCTION
           DISPLAY "=== Total: " WS-N
                   " | PASS: " WS-P
                   " | FAIL: " WS-F
           IF WS-F > 0
               STOP RUN RETURNING 1
           END-IF
           STOP RUN.

       PREP-TMP.
           CALL "SYSTEM" USING "mkdir -p /tmp/ad-test".

       PREP-PG.
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/15-autodebit/tests/unit/ad-setup-pg.sh".

       RESET-PG.
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/15-autodebit/tests/unit/ad-reset-pg.sh".

       CALL-RUN-DAILY.
           MOVE "EOD20260613-01" TO AD-RUN-BATCH-ID
           MOVE 20260613         TO AD-RUN-BUSINESS-DATE
           MOVE WS-FAILED-PATH   TO AD-RUN-FAILED-FILENAME
           MOVE WS-CKPT-PATH     TO AD-RUN-CHECKPOINT-FILENAME
           MOVE WS-SUMMARY-PATH  TO AD-RUN-SUMMARY-FILENAME
           CALL "AD-RUN-DAILY" USING AD-RUN-INPUT AD-RUN-OUTPUT.

       CALL-RUN-DAILY-DUP.
           MOVE "EOD20260613-DP" TO AD-RUN-BATCH-ID
           MOVE 20260613         TO AD-RUN-BUSINESS-DATE
           MOVE WS-FAILED-PATH   TO AD-RUN-FAILED-FILENAME
           MOVE WS-CKPT-PATH     TO AD-RUN-CHECKPOINT-FILENAME
           MOVE WS-SUMMARY-PATH  TO AD-RUN-SUMMARY-FILENAME
           CALL "AD-RUN-DAILY" USING AD-RUN-INPUT AD-RUN-OUTPUT.

       SEED-DUP-PAYER.
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/15-autodebit/tests/unit/ad-dup-seed.sh".

       REDUE-DUP-PAYER.
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/15-autodebit/tests/unit/ad-dup-redue.sh".

       CALL-REPORT.
           MOVE 20260613         TO AD-RPT-BUSINESS-DATE
           MOVE "EOD20260613-01" TO AD-RPT-BATCH-ID
           MOVE WS-SUMMARY-PATH  TO AD-RPT-SUMMARY-FILENAME
           MOVE WS-REPORT-PATH   TO AD-RPT-REPORT-FILENAME
           MOVE WS-FAILED-PATH   TO AD-RPT-FAILED-FILENAME
           CALL "AD-REPORT-SUMMARY" USING
                AD-REPORT-INPUT AD-REPORT-OUTPUT.

       TC01-HAPPY-1-POSTED.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG
           PERFORM CALL-RUN-DAILY
           IF AD-RUN-STATUS = "00" AND
              AD-OUT-INSTRUCTIONS-POSTED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " happy 1 posted"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" AD-RUN-STATUS
                       " posted=" AD-OUT-INSTRUCTIONS-POSTED
                       " NF=" AD-OUT-FAILED-NF
                       " CL=" AD-OUT-FAILED-CL
                       " SU=" AD-OUT-FAILED-SU
           END-IF.

       TC02-INSUFFICIENT-FUNDS.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF AD-OUT-FAILED-NF = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " NF=1 (= insufficient funds)"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " NF=" AD-OUT-FAILED-NF
           END-IF.

       TC03-DORMANT-ACCT.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF AD-OUT-FAILED-SU = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " SU=1 (= dormant)"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " SU=" AD-OUT-FAILED-SU
           END-IF.

       TC04-CLOSED-ACCT.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF AD-OUT-FAILED-CL = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " CL=1 (= closed)"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " CL=" AD-OUT-FAILED-CL
           END-IF.

       TC05-IDEMPOTENT-RERUN.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM CALL-RUN-DAILY
           IF AD-OUT-INSTRUCTIONS-POSTED = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " rerun no new posts"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " posted=" AD-OUT-INSTRUCTIONS-POSTED
           END-IF.

       TC06-FAILED-FILE-WRITTEN.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           CALL "SYSTEM" USING
                "test -s /tmp/ad-test/autodebit-failed.dat"
           IF RETURN-CODE = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " failed file written"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " failed file empty"
           END-IF.

       TC07-HELPER-VALIDATE-OK.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF AD-OUT-SKIPPED-HELPER = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " helper OK (= no rejects)"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " helper=" AD-OUT-SKIPPED-HELPER
           END-IF.

       TC08-AUTO-TM-CLOSED.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG
           PERFORM CALL-RUN-DAILY
           IF AD-OUT-AUTO-TERMINATED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " auto-TM=1"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " auto-TM=" AD-OUT-AUTO-TERMINATED
           END-IF.

       TC09-RETRY-FSM-CAP3.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG
           PERFORM CALL-RUN-DAILY
           PERFORM CALL-RUN-DAILY
           PERFORM CALL-RUN-DAILY
           IF AD-OUT-AUTO-SUSPENDED >= 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " retry FSM cap 3 → SP"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " auto-SP=" AD-OUT-AUTO-SUSPENDED
           END-IF.

       TC10-FREQUENCY-ADVANCE.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-PG
           PERFORM CALL-RUN-DAILY
           CALL "SYSTEM" USING
                "psql -h postgres -U cobol -d banking -tA -c ""SELECT next_due_date FROM autodebit_schedules WHERE instruction_id LIKE 'AD-TEST-001%'"" > /tmp/ad-test/nxt.out"
           IF AD-OUT-INSTRUCTIONS-POSTED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " frequency M advance"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
           END-IF.

       TC11-REPORT-HAPPY.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM CALL-REPORT
           IF AD-RPT-STATUS = "00" AND
              AD-RPT-PG-PT-COUNT >= 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " report happy"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" AD-RPT-STATUS
                       " PT=" AD-RPT-PG-PT-COUNT
           END-IF.

       TC12-DECLARATIVES-PRESENT.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF AD-RPT-FILE-FAILED-COUNT >= 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " DECLARATIVES OK; failed file has records"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " failed_count=" AD-RPT-FILE-FAILED-COUNT
           END-IF.

       TC13-MULTI-INSTR-SAME-PAYER.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM SEED-DUP-PAYER
           PERFORM CALL-RUN-DAILY-DUP
           IF AD-RUN-OK AND AD-OUT-INSTRUCTIONS-POSTED = 2
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " same-payer 2 posted"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" AD-RUN-STATUS
                       " posted=" AD-OUT-INSTRUCTIONS-POSTED
                       " already=" AD-OUT-SKIPPED-ALREADY
           END-IF.

       TC14-IDEMPOTENT-PER-INSTRUCTION.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM REDUE-DUP-PAYER
           PERFORM CALL-RUN-DAILY-DUP
           IF AD-OUT-INSTRUCTIONS-POSTED = 0 AND
              AD-OUT-SKIPPED-ALREADY = 2
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " rerun skips both (per-instr)"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " posted=" AD-OUT-INSTRUCTIONS-POSTED
                       " already=" AD-OUT-SKIPPED-ALREADY
           END-IF.

       END PROGRAM AD-TEST.
