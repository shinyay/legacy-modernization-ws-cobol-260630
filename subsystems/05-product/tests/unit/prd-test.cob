       IDENTIFICATION DIVISION.
       PROGRAM-ID. PRDTEST.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "prod-api.cpy".
       01 WS-N PIC 9(2) VALUE 0.
       01 WS-P PIC 9(2) VALUE 0.
       01 WS-F PIC 9(2) VALUE 0.
       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 05-product unit tests ===".

           MOVE "001" TO PRD-IN-CODE
           CALL "PROD-LOOKUP" USING PROD-INPUT PROD-OUTPUT
           ADD 1 TO WS-N
           IF PRD-OUT-STATUS = 0 AND PRD-OUT-TYPE = "S"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " lookup(001) type=S name=" PRD-OUT-NAME
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " lookup(001) status=" PRD-OUT-STATUS
           END-IF

           MOVE "002" TO PRD-IN-CODE
           CALL "PROD-LOOKUP" USING PROD-INPUT PROD-OUTPUT
           ADD 1 TO WS-N
           IF PRD-OUT-STATUS = 0 AND PRD-OUT-TYPE = "T"
              AND PRD-OUT-TERM-DAYS = 365
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " lookup(002) type=T term=365"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " lookup(002) type=" PRD-OUT-TYPE
                       " term=" PRD-OUT-TERM-DAYS
           END-IF

           MOVE "003" TO PRD-IN-CODE
           CALL "PROD-LOOKUP" USING PROD-INPUT PROD-OUTPUT
           ADD 1 TO WS-N
           IF PRD-OUT-STATUS = 0 AND PRD-OUT-TYPE = "C"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " lookup(003) type=C"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " lookup(003) status=" PRD-OUT-STATUS
           END-IF

           MOVE "999" TO PRD-IN-CODE
           CALL "PROD-LOOKUP" USING PROD-INPUT PROD-OUTPUT
           ADD 1 TO WS-N
           IF PRD-OUT-STATUS = 4
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " lookup(999) not-found"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " lookup(999) status=" PRD-OUT-STATUS
           END-IF

           DISPLAY "=== Total: " WS-N " | PASS: " WS-P " | FAIL: " WS-F.
           IF WS-F > 0 MOVE 1 TO RETURN-CODE END-IF
           STOP RUN.
