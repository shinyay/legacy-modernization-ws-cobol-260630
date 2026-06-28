       IDENTIFICATION DIVISION.
       PROGRAM-ID. STMT-TEST.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  WS-N           PIC 9(3) VALUE 0.
       01  WS-P           PIC 9(3) VALUE 0.
       01  WS-F           PIC 9(3) VALUE 0.
       01  WS-TC-NUM      PIC 9(3).

           COPY "stmt-api.cpy".

       01  WS-PATHS.
           05  WS-RPT-PATH       PIC X(80) VALUE
               "/tmp/stmt-test/statement.rpt".
           05  WS-SUM-PATH       PIC X(80) VALUE
               "/tmp/stmt-test/statement-summary.txt".
           05  WS-RPT-PATH-2     PIC X(80) VALUE
               "/tmp/stmt-test/statement-rerun.rpt".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 17-statement unit tests (Phase 6) ==="
           PERFORM PREP-TMP
           PERFORM PREP-PG
           PERFORM TC01-HAPPY-DAILY
           PERFORM TC02-ACCOUNTS-PROCESSED
           PERFORM TC03-OUTPUT-FILE-EXISTS
           PERFORM TC04-OUTPUT-HAS-HEADER
           PERFORM TC05-OUTPUT-HAS-DETAIL-LINES
           PERFORM TC06-OUTPUT-HAS-OPENING-BALANCE
           PERFORM TC07-OUTPUT-HAS-CLOSING-BALANCE
           PERFORM TC08-EMPTY-ACCT-INCLUDED
           PERFORM TC09-MONTHLY-MODE
           PERFORM TC10-IDEMPOTENT-RERUN
           PERFORM TC11-SUMMARY-FILE
           PERFORM TC12-INVALID-MODE
           PERFORM TC13-AUDIT-EMITTED
           DISPLAY "=== Total: " WS-N
                   " | PASS: " WS-P
                   " | FAIL: " WS-F
           IF WS-F > 0
               STOP RUN RETURNING 1
           END-IF
           STOP RUN.

       PREP-TMP.
           CALL "SYSTEM" USING "mkdir -p /tmp/stmt-test".

       PREP-PG.
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/17-statement/tests/unit/stmt-setup-pg.sh".

       CALL-STMT.
           MOVE "STMT-TEST-001 " TO STMT-BATCH-ID
           MOVE 20260613         TO STMT-BUSINESS-DATE
           MOVE "D"              TO STMT-MODE
           MOVE WS-RPT-PATH      TO STMT-OUTPUT-FILENAME
           MOVE WS-SUM-PATH      TO STMT-SUMMARY-FILENAME
           MOVE "N"              TO STMT-SKIP-INACTIVE
           CALL "STMT-GENERATE-BATCH" USING STMT-INPUT STMT-OUTPUT
           CANCEL "STMT-GENERATE-BATCH".

       CALL-STMT-MONTHLY.
           MOVE "STMT-TEST-002 " TO STMT-BATCH-ID
           MOVE 20260613         TO STMT-BUSINESS-DATE
           MOVE "M"              TO STMT-MODE
           MOVE WS-RPT-PATH      TO STMT-OUTPUT-FILENAME
           MOVE WS-SUM-PATH      TO STMT-SUMMARY-FILENAME
           MOVE "N"              TO STMT-SKIP-INACTIVE
           CALL "STMT-GENERATE-BATCH" USING STMT-INPUT STMT-OUTPUT
           CANCEL "STMT-GENERATE-BATCH".

       CALL-STMT-RERUN.
           MOVE "STMT-TEST-001 " TO STMT-BATCH-ID
           MOVE 20260613         TO STMT-BUSINESS-DATE
           MOVE "D"              TO STMT-MODE
           MOVE WS-RPT-PATH-2    TO STMT-OUTPUT-FILENAME
           MOVE WS-SUM-PATH      TO STMT-SUMMARY-FILENAME
           MOVE "N"              TO STMT-SKIP-INACTIVE
           CALL "STMT-GENERATE-BATCH" USING STMT-INPUT STMT-OUTPUT
           CANCEL "STMT-GENERATE-BATCH".

       TC01-HAPPY-DAILY.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM CALL-STMT
           IF STMT-OK
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " happy daily"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" STMT-STATUS
                       " accts=" STMT-OUT-ACCOUNTS-PROCESSED
           END-IF.

       TC02-ACCOUNTS-PROCESSED.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF STMT-OUT-ACCOUNTS-PROCESSED >= 5
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " 5+ accts processed (= "
                       STMT-OUT-ACCOUNTS-PROCESSED ")"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " accts=" STMT-OUT-ACCOUNTS-PROCESSED
           END-IF.

       TC03-OUTPUT-FILE-EXISTS.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           CALL "SYSTEM" USING "test -s /tmp/stmt-test/statement.rpt"
           IF RETURN-CODE = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " .rpt file non-empty"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " .rpt file empty/missing"
           END-IF.

       TC04-OUTPUT-HAS-HEADER.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           CALL "SYSTEM" USING
                "grep -q 'PRACTICE BANK STATEMENT' /tmp/stmt-test/statement.rpt"
           IF RETURN-CODE = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " page heading found"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " no header"
           END-IF.

       TC05-OUTPUT-HAS-DETAIL-LINES.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           IF STMT-OUT-LINES-WRITTEN >= 10
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " 10+ details (= "
                       STMT-OUT-LINES-WRITTEN ")"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " lines=" STMT-OUT-LINES-WRITTEN
           END-IF.

       TC06-OUTPUT-HAS-OPENING-BALANCE.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           CALL "SYSTEM" USING
                "grep -q 'Opening Balance' /tmp/stmt-test/statement.rpt"
           IF RETURN-CODE = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " opening balance line"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " no opening balance"
           END-IF.

       TC07-OUTPUT-HAS-CLOSING-BALANCE.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           CALL "SYSTEM" USING
                "grep -q 'Closing Balance' /tmp/stmt-test/statement.rpt"
           IF RETURN-CODE = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " closing balance line"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " no closing balance"
           END-IF.

       TC08-EMPTY-ACCT-INCLUDED.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           CALL "SYSTEM" USING
                "grep -q '0010010099405' /tmp/stmt-test/statement.rpt"
           IF RETURN-CODE = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " T5 empty acct emitted"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " T5 missing from output"
           END-IF.

       TC09-MONTHLY-MODE.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM CALL-STMT-MONTHLY
           IF STMT-OK
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " monthly mode OK"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" STMT-STATUS
           END-IF.

       TC10-IDEMPOTENT-RERUN.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM CALL-STMT
           PERFORM CALL-STMT-RERUN
           CALL "SYSTEM" USING
                "diff /tmp/stmt-test/statement.rpt /tmp/stmt-test/statement-rerun.rpt > /dev/null 2>&1"
           IF RETURN-CODE = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " rerun byte-identical"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rerun differs"
           END-IF.

       TC11-SUMMARY-FILE.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           CALL "SYSTEM" USING
                "test -s /tmp/stmt-test/statement-summary.txt"
           IF RETURN-CODE = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " summary file written"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " no summary"
           END-IF.

       TC12-INVALID-MODE.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           MOVE "STMT-TEST-003 " TO STMT-BATCH-ID
           MOVE 20260613         TO STMT-BUSINESS-DATE
           MOVE "X"              TO STMT-MODE
           MOVE WS-RPT-PATH      TO STMT-OUTPUT-FILENAME
           MOVE WS-SUM-PATH      TO STMT-SUMMARY-FILENAME
           MOVE "N"              TO STMT-SKIP-INACTIVE
           CALL "STMT-GENERATE-BATCH" USING STMT-INPUT STMT-OUTPUT
           CANCEL "STMT-GENERATE-BATCH"
           IF STMT-INVALID-INPUT
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " invalid mode rejected"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " st=" STMT-STATUS
           END-IF.

       TC13-AUDIT-EMITTED.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           CALL "SYSTEM" USING
                "bash /workspace/subsystems/17-statement/tests/unit/check-audit.sh"
           IF RETURN-CODE = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " audit rows present"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " no audit rows"
           END-IF.

       END PROGRAM STMT-TEST.
