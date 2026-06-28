       IDENTIFICATION DIVISION.
       PROGRAM-ID. IRATETEST.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "irate-api.cpy".
       01 WS-N PIC 9(2) VALUE 0.
       01 WS-P PIC 9(2) VALUE 0.
       01 WS-F PIC 9(2) VALUE 0.

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 06-interestrate unit tests ===".

           MOVE "001" TO IR-IN-PRODUCT
           MOVE 1 TO IR-IN-TIER
           MOVE 20260101 TO IR-IN-EFFECTIVE
           CALL "IRATE-LOOKUP" USING IRATE-INPUT IRATE-OUTPUT
           ADD 1 TO WS-N
           IF IR-OUT-STATUS = 0 AND IR-OUT-RATE-MICRO = 1000
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " lookup(001,1,20260101) rate=" IR-OUT-RATE-MICRO
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " status=" IR-OUT-STATUS " rate=" IR-OUT-RATE-MICRO
           END-IF

           MOVE "002" TO IR-IN-PRODUCT
           MOVE 1 TO IR-IN-TIER
           MOVE 20270101 TO IR-IN-EFFECTIVE
           CALL "IRATE-LOOKUP" USING IRATE-INPUT IRATE-OUTPUT
           ADD 1 TO WS-N
           IF IR-OUT-STATUS = 0 AND IR-OUT-RATE-MICRO = 55000
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " lookup(002,1,20270101) rate=" IR-OUT-RATE-MICRO
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " status=" IR-OUT-STATUS " rate=" IR-OUT-RATE-MICRO
           END-IF

           MOVE "003" TO IR-IN-PRODUCT
           MOVE 1 TO IR-IN-TIER
           MOVE 20260101 TO IR-IN-EFFECTIVE
           CALL "IRATE-LOOKUP" USING IRATE-INPUT IRATE-OUTPUT
           ADD 1 TO WS-N
           IF IR-OUT-STATUS = 0 AND IR-OUT-RATE-MICRO = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " lookup(003,1,20260101) rate=0"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N
           END-IF

           MOVE "999" TO IR-IN-PRODUCT
           CALL "IRATE-LOOKUP" USING IRATE-INPUT IRATE-OUTPUT
           ADD 1 TO WS-N
           IF IR-OUT-STATUS = 4
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " lookup(999) not-found"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N
           END-IF

           DISPLAY "=== Total: " WS-N " | PASS: " WS-P " | FAIL: " WS-F.
           IF WS-F > 0 MOVE 1 TO RETURN-CODE END-IF
           STOP RUN.
