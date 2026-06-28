       IDENTIFICATION DIVISION.
       PROGRAM-ID. FEETEST.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "fs-api.cpy".
       01 WS-N PIC 9(2) VALUE 0.
       01 WS-P PIC 9(2) VALUE 0.
       01 WS-F PIC 9(2) VALUE 0.
       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 07-feeschedule unit tests ===".

           MOVE 40 TO FS-IN-CATEGORY
           MOVE 1 TO FS-IN-TIER
           MOVE 20260101 TO FS-IN-EFFECTIVE
           CALL "FEE-LOOKUP-BY-TIER" USING FS-INPUT FS-OUTPUT
           ADD 1 TO WS-N
           IF FS-OUT-STATUS = 0 AND FS-OUT-FEE-JPY = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " wire-tier1 2026 fee=0"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " status=" FS-OUT-STATUS " fee=" FS-OUT-FEE-JPY
           END-IF

           MOVE 40 TO FS-IN-CATEGORY
           MOVE 3 TO FS-IN-TIER
           MOVE 20260101 TO FS-IN-EFFECTIVE
           CALL "FEE-LOOKUP-BY-TIER" USING FS-INPUT FS-OUTPUT
           ADD 1 TO WS-N
           IF FS-OUT-STATUS = 0 AND FS-OUT-FEE-JPY = 880
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " wire-tier3 2026 fee=880"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " fee=" FS-OUT-FEE-JPY
           END-IF

           MOVE 20270101 TO FS-IN-EFFECTIVE
           CALL "FEE-LOOKUP-BY-TIER" USING FS-INPUT FS-OUTPUT
           ADD 1 TO WS-N
           IF FS-OUT-STATUS = 0 AND FS-OUT-FEE-JPY = 968
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " wire-tier3 2027 fee=968"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " fee=" FS-OUT-FEE-JPY
           END-IF

           MOVE 99 TO FS-IN-CATEGORY
           CALL "FEE-LOOKUP-BY-TIER" USING FS-INPUT FS-OUTPUT
           ADD 1 TO WS-N
           IF FS-OUT-STATUS = 4
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " cat 99 not-found"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N
           END-IF

           DISPLAY "=== Total: " WS-N " | PASS: " WS-P " | FAIL: " WS-F.
           IF WS-F > 0 MOVE 1 TO RETURN-CODE END-IF
           STOP RUN.
