       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSTTEST.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "cust-api.cpy".

       01 WS-N PIC 9(3) VALUE 0.
       01 WS-P PIC 9(3) VALUE 0.
       01 WS-F PIC 9(3) VALUE 0.
       01 WS-COUNT PIC 9(4) VALUE 0.

       01 CSC-INPUT.
           05  CSC-ID            PIC 9(10).
           05  CSC-NEW-STATUS    PIC X(1).
           05  CSC-BUSINESS-DATE PIC 9(8).
       01 CSC-OUTPUT.
           05  CSC-OUT-STATUS    PIC 9(2).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 03-customer unit tests ===".

           DISPLAY " ".
           DISPLAY "--- CUST-LOOKUP (3 cases) ---".

           MOVE 0000000001 TO CUST-IN-ID
           CALL "CUST-LOOKUP" USING CUST-INPUT CUST-OUTPUT
           ADD 1 TO WS-N
           IF CUST-OUT-STATUS = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " lookup(1) status_code=" CUST-OUT-STATUS-CODE
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " lookup(1) status=" CUST-OUT-STATUS
           END-IF

           MOVE 0000000005 TO CUST-IN-ID
           CALL "CUST-LOOKUP" USING CUST-INPUT CUST-OUTPUT
           ADD 1 TO WS-N
           IF CUST-OUT-STATUS = 0 AND CUST-OUT-ID = 5
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " lookup(5)"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " lookup(5) status=" CUST-OUT-STATUS
           END-IF

           MOVE 9999999999 TO CUST-IN-ID
           CALL "CUST-LOOKUP" USING CUST-INPUT CUST-OUTPUT
           ADD 1 TO WS-N
           IF CUST-OUT-STATUS = 4
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " lookup(9...) not-found"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " status=" CUST-OUT-STATUS
           END-IF

           DISPLAY " ".
           DISPLAY "--- CUST-SEARCH-BY-KANA (prefix scan) ---".
           MOVE "タナカ" TO CUST-IN-KANA
           MOVE "K" TO CUST-IN-OP
           MOVE 0 TO WS-COUNT
           MOVE 0 TO CUST-OUT-STATUS
           PERFORM UNTIL CUST-OUT-STATUS = 10 OR WS-COUNT > 20
               CALL "CUST-SEARCH-BY-KANA" USING CUST-INPUT CUST-OUTPUT
               IF CUST-OUT-STATUS = 0
                   ADD 1 TO WS-COUNT
                   DISPLAY "  Tanaka match: id=" CUST-OUT-ID
                           " kana=" CUST-OUT-KANA(1:20)
               END-IF
               MOVE " " TO CUST-IN-OP
           END-PERFORM
           ADD 1 TO WS-N
           IF WS-COUNT > 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " search-by-kana(tanaka*) count=" WS-COUNT
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " no kana matches"
           END-IF

           DISPLAY " ".
           DISPLAY "--- CUST-LIST-ALL (expects 101 = 1 system + 100) ---".
           MOVE "A" TO CUST-IN-OP
           MOVE 0 TO CUST-OUT-STATUS
           MOVE 0 TO WS-COUNT
           PERFORM UNTIL CUST-OUT-STATUS = 10
               CALL "CUST-LIST-ALL" USING CUST-INPUT CUST-OUTPUT
               IF CUST-OUT-STATUS = 0
                   ADD 1 TO WS-COUNT
               END-IF
               MOVE " " TO CUST-IN-OP
           END-PERFORM
           ADD 1 TO WS-N
           IF WS-COUNT = 101
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " list-all count=" WS-COUNT
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " list-all count=" WS-COUNT
                       " (expected 101)"
           END-IF

           DISPLAY " ".
           DISPLAY "--- CUST-STATUS-CHANGE (with AUD-WRITE) ---".
           MOVE 0000000002 TO CSC-ID
           MOVE "S" TO CSC-NEW-STATUS
           MOVE 20260611 TO CSC-BUSINESS-DATE
           CALL "CUST-STATUS-CHANGE" USING CSC-INPUT CSC-OUTPUT
           ADD 1 TO WS-N
           IF CSC-OUT-STATUS = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " status-change(2 -> S) ok"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " status=" CSC-OUT-STATUS
           END-IF

           MOVE 0000000002 TO CUST-IN-ID
           CALL "CUST-LOOKUP" USING CUST-INPUT CUST-OUTPUT
           ADD 1 TO WS-N
           IF CUST-OUT-STATUS = 0 AND CUST-OUT-STATUS-CODE = "S"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " verify status=S after change"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " status_code=" CUST-OUT-STATUS-CODE
           END-IF

           DISPLAY " ".
           DISPLAY "=== Total: " WS-N " | PASS: " WS-P " | FAIL: " WS-F.
           IF WS-F > 0 MOVE 1 TO RETURN-CODE END-IF
           STOP RUN.
