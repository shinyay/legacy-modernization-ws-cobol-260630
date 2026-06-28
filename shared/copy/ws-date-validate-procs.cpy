       IS-LEAP-YEAR.
           MOVE 'N' TO WS-DV-LEAP-FLAG.
           IF FUNCTION MOD(WS-DV-YYYY, 4) = 0 THEN
               IF FUNCTION MOD(WS-DV-YYYY, 100) NOT = 0 THEN
                   MOVE 'Y' TO WS-DV-LEAP-FLAG
               ELSE
                   IF FUNCTION MOD(WS-DV-YYYY, 400) = 0 THEN
                       MOVE 'Y' TO WS-DV-LEAP-FLAG
                   END-IF
               END-IF
           END-IF.

       IS-VALID-GREGORIAN-DATE.
           MOVE 0 TO WS-DV-RC.
           MOVE WS-DV-IN-YYYY TO WS-DV-YYYY.
           MOVE WS-DV-IN-MM   TO WS-DV-MM.
           MOVE WS-DV-IN-DD   TO WS-DV-DD.
           IF WS-DV-YYYY < 1900 OR WS-DV-YYYY > 9999 THEN
               MOVE 3 TO WS-DV-RC
           ELSE
               IF WS-DV-MM < 1 OR WS-DV-MM > 12 THEN
                   MOVE 1 TO WS-DV-RC
               ELSE
                   MOVE WS-DV-DAYS-OF-MONTH(WS-DV-MM)
                       TO WS-DV-EXPECTED-DAYS
                   IF WS-DV-MM = 2 THEN
                       PERFORM IS-LEAP-YEAR
                       IF WS-DV-IS-LEAP THEN
                           MOVE 29 TO WS-DV-EXPECTED-DAYS
                       END-IF
                   END-IF
                   IF WS-DV-DD < 1
                      OR WS-DV-DD > WS-DV-EXPECTED-DAYS THEN
                       MOVE 2 TO WS-DV-RC
                   END-IF
               END-IF
           END-IF.

       SUBTRACT-1-DAY.
           MOVE 0 TO WS-DV-RC.
           MOVE WS-DV-IN-YYYY TO WS-DV-YYYY.
           MOVE WS-DV-IN-MM   TO WS-DV-MM.
           MOVE WS-DV-IN-DD   TO WS-DV-DD.
           IF WS-DV-YYYY < 1900 OR WS-DV-YYYY > 9999 THEN
               MOVE 3 TO WS-DV-RC
               MOVE WS-DV-INPUT-DATE TO WS-DV-OUTPUT-DATE
           ELSE
               IF WS-DV-DD > 1 THEN
                   SUBTRACT 1 FROM WS-DV-DD
               ELSE
                   IF WS-DV-MM > 1 THEN
                       SUBTRACT 1 FROM WS-DV-MM
                       MOVE WS-DV-DAYS-OF-MONTH(WS-DV-MM) TO WS-DV-DD
                       IF WS-DV-MM = 2 THEN
                           PERFORM IS-LEAP-YEAR
                           IF WS-DV-IS-LEAP THEN
                               MOVE 29 TO WS-DV-DD
                           END-IF
                       END-IF
                   ELSE
                       SUBTRACT 1 FROM WS-DV-YYYY
                       MOVE 12 TO WS-DV-MM
                       MOVE 31 TO WS-DV-DD
                   END-IF
               END-IF
               COMPUTE WS-DV-OUTPUT-DATE =
                   WS-DV-YYYY * 10000 + WS-DV-MM * 100 + WS-DV-DD
           END-IF.
