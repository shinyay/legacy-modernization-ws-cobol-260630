       IDENTIFICATION DIVISION.
       PROGRAM-ID. CSRCHTEST.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "csrch-api.cpy".
       01 WS-N PIC 9(3) VALUE 0.
       01 WS-P PIC 9(3) VALUE 0.
       01 WS-F PIC 9(3) VALUE 0.
       01 WS-COUNT PIC 9(3) VALUE 0.

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 04-customersearch unit tests ===".

           DISPLAY " ".
           DISPLAY "--- CSRCH-BY-ADDRESS (Tokyo) ---".
           MOVE "東京都" TO CSRCH-ADDR-SUBSTR
           MOVE "D" TO CSRCH-OP
           MOVE 0 TO CSRCH-STATUS
           MOVE 0 TO WS-COUNT
           PERFORM UNTIL CSRCH-STATUS = 10
               CALL "CSRCH-BY-ADDRESS" USING CSRCH-INPUT CSRCH-OUTPUT
               IF CSRCH-STATUS = 0
                   ADD 1 TO WS-COUNT
               END-IF
               MOVE " " TO CSRCH-OP
           END-PERFORM
           ADD 1 TO WS-N
           IF WS-COUNT > 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " by-address(Tokyo) matches=" WS-COUNT
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " no matches"
           END-IF

           DISPLAY " ".
           DISPLAY "--- CSRCH-LIST-PAGED (page size 5, no cursor) ---".
           MOVE 5 TO CSRCH-PAGE-SIZE
           MOVE 0 TO CSRCH-START-AFTER
           MOVE "P" TO CSRCH-OP
           MOVE 0 TO CSRCH-STATUS
           MOVE 0 TO WS-COUNT
           PERFORM UNTIL CSRCH-STATUS = 10
               CALL "CSRCH-LIST-PAGED" USING CSRCH-INPUT CSRCH-OUTPUT
               IF CSRCH-STATUS = 0
                   ADD 1 TO WS-COUNT
                   DISPLAY "  page row: id=" CSRCH-MATCH-ID
               END-IF
               MOVE " " TO CSRCH-OP
           END-PERFORM
           ADD 1 TO WS-N
           IF WS-COUNT = 5
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " list-paged returned 5 / last=" CSRCH-LAST-ID
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " count=" WS-COUNT
           END-IF

           DISPLAY " ".
           DISPLAY "=== Total: " WS-N " | PASS: " WS-P " | FAIL: " WS-F.
           IF WS-F > 0 MOVE 1 TO RETURN-CODE END-IF
           STOP RUN.
