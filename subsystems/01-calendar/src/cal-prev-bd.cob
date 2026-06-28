       IDENTIFICATION DIVISION.
       PROGRAM-ID. CAL-PREV-BD.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-DATE-INT             PIC 9(8).
       01  WS-LOCAL-INPUT.
           05  WS-LI-DATE          PIC 9(8).
       01  WS-LOCAL-OUTPUT.
           05  WS-LO-STATUS        PIC 9(2).
           05  WS-LO-DAY-TYPE      PIC X(1).
           05  WS-LO-HOLIDAY-NAME  PIC X(40).
           05  WS-LO-NEXT-DATE     PIC 9(8).
       01  WS-ITER-COUNT           PIC 9(2) VALUE 0.
       01  WS-MAX-ITER             PIC 9(2) VALUE 10.

       LINKAGE SECTION.
       COPY "cal-api.cpy".

       PROCEDURE DIVISION USING CAL-INPUT CAL-OUTPUT.
       MAIN-LOGIC.
           MOVE 00 TO CAL-STATUS.
           MOVE ZERO TO CAL-OUTPUT-NEXT-DATE.
           MOVE SPACES TO CAL-OUTPUT-DAY-TYPE.
           MOVE SPACES TO CAL-OUTPUT-HOLIDAY-NAME.

           IF CAL-INPUT-DATE NOT NUMERIC THEN
               MOVE 08 TO CAL-STATUS
               GOBACK
           END-IF.

           COMPUTE WS-DATE-INT =
               FUNCTION INTEGER-OF-DATE(CAL-INPUT-DATE).

           PERFORM UNTIL WS-ITER-COUNT > WS-MAX-ITER
               SUBTRACT 1 FROM WS-DATE-INT
               COMPUTE WS-LI-DATE =
                   FUNCTION DATE-OF-INTEGER(WS-DATE-INT)
               ADD 1 TO WS-ITER-COUNT

               MOVE WS-LI-DATE TO WS-LOCAL-INPUT
               CALL "CAL-LOOKUP" USING WS-LOCAL-INPUT WS-LOCAL-OUTPUT
               EVALUATE WS-LO-STATUS
                   WHEN 00
                       IF WS-LO-DAY-TYPE = "B" THEN
                           MOVE WS-LI-DATE TO CAL-OUTPUT-NEXT-DATE
                           MOVE "B" TO CAL-OUTPUT-DAY-TYPE
                           MOVE 00 TO CAL-STATUS
                           GOBACK
                       END-IF
                   WHEN 04
                       MOVE 04 TO CAL-STATUS
                       GOBACK
                   WHEN OTHER
                       MOVE WS-LO-STATUS TO CAL-STATUS
                       GOBACK
               END-EVALUATE
           END-PERFORM.

           MOVE 16 TO CAL-STATUS.
           GOBACK.
