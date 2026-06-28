       IDENTIFICATION DIVISION.
       PROGRAM-ID. CALTEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "cal-api.cpy".

       01  WS-TEST-NUM     PIC 9(3) VALUE 0.
       01  WS-PASS         PIC 9(3) VALUE 0.
       01  WS-FAIL         PIC 9(3) VALUE 0.
       01  WS-EXP-STATUS   PIC 9(2).
       01  WS-EXP-DAY-TYPE PIC X(1).
       01  WS-EXP-DATE     PIC 9(8).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 01-calendar unit tests ===".

           DISPLAY " ".
           DISPLAY "--- CAL-LOOKUP (8 cases) ---".

           MOVE 20260101 TO CAL-INPUT-DATE
           MOVE 00 TO WS-EXP-STATUS  MOVE "H" TO WS-EXP-DAY-TYPE
           PERFORM RUN-LOOKUP

           MOVE 20260105 TO CAL-INPUT-DATE
           MOVE 00 TO WS-EXP-STATUS  MOVE "B" TO WS-EXP-DAY-TYPE
           PERFORM RUN-LOOKUP

           MOVE 20260103 TO CAL-INPUT-DATE
           MOVE 00 TO WS-EXP-STATUS  MOVE "W" TO WS-EXP-DAY-TYPE
           PERFORM RUN-LOOKUP

           MOVE 20260104 TO CAL-INPUT-DATE
           MOVE 00 TO WS-EXP-STATUS  MOVE "W" TO WS-EXP-DAY-TYPE
           PERFORM RUN-LOOKUP

           MOVE 20251231 TO CAL-INPUT-DATE
           MOVE 04 TO WS-EXP-STATUS  MOVE " " TO WS-EXP-DAY-TYPE
           PERFORM RUN-LOOKUP

           MOVE 20310101 TO CAL-INPUT-DATE
           MOVE 04 TO WS-EXP-STATUS  MOVE " " TO WS-EXP-DAY-TYPE
           PERFORM RUN-LOOKUP

           MOVE 20301231 TO CAL-INPUT-DATE
           MOVE 00 TO WS-EXP-STATUS  MOVE "B" TO WS-EXP-DAY-TYPE
           PERFORM RUN-LOOKUP

           MOVE 20260101 TO CAL-INPUT-DATE
           MOVE 00 TO WS-EXP-STATUS  MOVE "H" TO WS-EXP-DAY-TYPE
           PERFORM RUN-LOOKUP

           DISPLAY " ".
           DISPLAY "--- CAL-NEXT-BD (4 cases) ---".

           MOVE 20260109 TO CAL-INPUT-DATE
           MOVE 00 TO WS-EXP-STATUS  MOVE 20260113 TO WS-EXP-DATE
           PERFORM RUN-NEXT-BD

           MOVE 20260505 TO CAL-INPUT-DATE
           MOVE 00 TO WS-EXP-STATUS  MOVE 20260507 TO WS-EXP-DATE
           PERFORM RUN-NEXT-BD

           MOVE 20261231 TO CAL-INPUT-DATE
           MOVE 00 TO WS-EXP-STATUS  MOVE 20270104 TO WS-EXP-DATE
           PERFORM RUN-NEXT-BD

           MOVE 20301231 TO CAL-INPUT-DATE
           MOVE 04 TO WS-EXP-STATUS  MOVE 0 TO WS-EXP-DATE
           PERFORM RUN-NEXT-BD

           DISPLAY " ".
           DISPLAY "--- CAL-PREV-BD (3 cases) ---".

           MOVE 20260112 TO CAL-INPUT-DATE
           MOVE 00 TO WS-EXP-STATUS  MOVE 20260109 TO WS-EXP-DATE
           PERFORM RUN-PREV-BD

           MOVE 20270104 TO CAL-INPUT-DATE
           MOVE 00 TO WS-EXP-STATUS  MOVE 20261231 TO WS-EXP-DATE
           PERFORM RUN-PREV-BD

           MOVE 20260101 TO CAL-INPUT-DATE
           MOVE 04 TO WS-EXP-STATUS  MOVE 0 TO WS-EXP-DATE
           PERFORM RUN-PREV-BD

           DISPLAY " ".
           DISPLAY "=== Total: " WS-TEST-NUM
                   " | PASS: " WS-PASS
                   " | FAIL: " WS-FAIL.
           IF WS-FAIL > 0 THEN
               MOVE 1 TO RETURN-CODE
           END-IF.
           STOP RUN.

       RUN-LOOKUP.
           ADD 1 TO WS-TEST-NUM
           CALL "CAL-LOOKUP" USING CAL-INPUT CAL-OUTPUT
           IF CAL-STATUS = WS-EXP-STATUS
              AND (WS-EXP-STATUS NOT = 0
                   OR CAL-OUTPUT-DAY-TYPE = WS-EXP-DAY-TYPE) THEN
               ADD 1 TO WS-PASS
               DISPLAY "  [PASS] " WS-TEST-NUM
                       " lookup(" CAL-INPUT-DATE
                       ") status=" CAL-STATUS
                       " day=" CAL-OUTPUT-DAY-TYPE
           ELSE
               ADD 1 TO WS-FAIL
               DISPLAY "  [FAIL] " WS-TEST-NUM
                       " lookup(" CAL-INPUT-DATE
                       ") status=" CAL-STATUS
                       " day=" CAL-OUTPUT-DAY-TYPE
                       " (expected status=" WS-EXP-STATUS
                       " day=" WS-EXP-DAY-TYPE ")"
           END-IF.

       RUN-NEXT-BD.
           ADD 1 TO WS-TEST-NUM
           CALL "CAL-NEXT-BD" USING CAL-INPUT CAL-OUTPUT
           IF CAL-STATUS = WS-EXP-STATUS
              AND (WS-EXP-STATUS NOT = 0
                   OR CAL-OUTPUT-NEXT-DATE = WS-EXP-DATE) THEN
               ADD 1 TO WS-PASS
               DISPLAY "  [PASS] " WS-TEST-NUM
                       " next-bd(" CAL-INPUT-DATE
                       ") -> " CAL-OUTPUT-NEXT-DATE
                       " status=" CAL-STATUS
           ELSE
               ADD 1 TO WS-FAIL
               DISPLAY "  [FAIL] " WS-TEST-NUM
                       " next-bd(" CAL-INPUT-DATE
                       ") -> " CAL-OUTPUT-NEXT-DATE
                       " status=" CAL-STATUS
                       " (expected " WS-EXP-DATE
                       " status=" WS-EXP-STATUS ")"
           END-IF.

       RUN-PREV-BD.
           ADD 1 TO WS-TEST-NUM
           CALL "CAL-PREV-BD" USING CAL-INPUT CAL-OUTPUT
           IF CAL-STATUS = WS-EXP-STATUS
              AND (WS-EXP-STATUS NOT = 0
                   OR CAL-OUTPUT-NEXT-DATE = WS-EXP-DATE) THEN
               ADD 1 TO WS-PASS
               DISPLAY "  [PASS] " WS-TEST-NUM
                       " prev-bd(" CAL-INPUT-DATE
                       ") -> " CAL-OUTPUT-NEXT-DATE
                       " status=" CAL-STATUS
           ELSE
               ADD 1 TO WS-FAIL
               DISPLAY "  [FAIL] " WS-TEST-NUM
                       " prev-bd(" CAL-INPUT-DATE
                       ") -> " CAL-OUTPUT-NEXT-DATE
                       " status=" CAL-STATUS
                       " (expected " WS-EXP-DATE
                       " status=" WS-EXP-STATUS ")"
           END-IF.
