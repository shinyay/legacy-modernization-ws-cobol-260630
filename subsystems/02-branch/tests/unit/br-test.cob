       IDENTIFICATION DIVISION.
       PROGRAM-ID. BRTEST.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "br-api.cpy".
       01  WS-N   PIC 9(3) VALUE 0.
       01  WS-P   PIC 9(3) VALUE 0.
       01  WS-F   PIC 9(3) VALUE 0.
       01  WS-COUNT PIC 9(3) VALUE 0.

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 02-branch unit tests ===".

           DISPLAY " ".
           DISPLAY "--- BR-LOOKUP (4 cases) ---".

           MOVE "001" TO BR-IN-CODE
           MOVE "L" TO BR-IN-OP
           CALL "BR-LOOKUP" USING BR-INPUT BR-OUTPUT
           ADD 1 TO WS-N
           IF BR-OUT-STATUS = 0 AND BR-OUT-CODE = "001"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " lookup(001) name=" BR-OUT-NAME-KANJI
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " lookup(001) status=" BR-OUT-STATUS
           END-IF

           MOVE "005" TO BR-IN-CODE
           CALL "BR-LOOKUP" USING BR-INPUT BR-OUTPUT
           ADD 1 TO WS-N
           IF BR-OUT-STATUS = 0 AND BR-OUT-REGION(1:5) = "Osaka"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " lookup(005) region=" BR-OUT-REGION
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " lookup(005) region=" BR-OUT-REGION
                       " status=" BR-OUT-STATUS
           END-IF

           MOVE "999" TO BR-IN-CODE
           CALL "BR-LOOKUP" USING BR-INPUT BR-OUTPUT
           ADD 1 TO WS-N
           IF BR-OUT-STATUS = 4
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " lookup(999) not-found"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " lookup(999) status=" BR-OUT-STATUS
           END-IF

           MOVE "010" TO BR-IN-CODE
           CALL "BR-LOOKUP" USING BR-INPUT BR-OUTPUT
           ADD 1 TO WS-N
           IF BR-OUT-STATUS = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " lookup(010) region=" BR-OUT-REGION
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N
           END-IF

           DISPLAY " ".
           DISPLAY "--- BR-LIST-BY-REGION (Tokyo expects 4 records) ---".
           MOVE "Tokyo" TO BR-IN-REGION
           MOVE "R" TO BR-IN-OP
           MOVE 0 TO WS-COUNT
           PERFORM UNTIL BR-OUT-STATUS = 10
               CALL "BR-LIST-BY-REGION" USING BR-INPUT BR-OUTPUT
               IF BR-OUT-STATUS = 0
                   ADD 1 TO WS-COUNT
                   DISPLAY "  Tokyo branch: " BR-OUT-CODE
                           " region=" BR-OUT-REGION
               END-IF
               MOVE " " TO BR-IN-OP
           END-PERFORM
           ADD 1 TO WS-N
           IF WS-COUNT = 4
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " list-by-region(Tokyo) count=" WS-COUNT
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N
                       " list-by-region(Tokyo) count=" WS-COUNT
                       " (expected 4)"
           END-IF

           DISPLAY " ".
           DISPLAY "--- BR-LIST-ALL (expects 10 records) ---".
           MOVE "A" TO BR-IN-OP
           MOVE 0 TO BR-OUT-STATUS
           MOVE 0 TO WS-COUNT
           PERFORM UNTIL BR-OUT-STATUS = 10
               CALL "BR-LIST-ALL" USING BR-INPUT BR-OUTPUT
               IF BR-OUT-STATUS = 0
                   ADD 1 TO WS-COUNT
               END-IF
               MOVE " " TO BR-IN-OP
           END-PERFORM
           ADD 1 TO WS-N
           IF WS-COUNT = 10
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " list-all count=" WS-COUNT
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-N " list-all count=" WS-COUNT
                       " (expected 10)"
           END-IF

           DISPLAY " ".
           DISPLAY "=== Total: " WS-N " | PASS: " WS-P " | FAIL: " WS-F.
           IF WS-F > 0 MOVE 1 TO RETURN-CODE END-IF
           STOP RUN.
