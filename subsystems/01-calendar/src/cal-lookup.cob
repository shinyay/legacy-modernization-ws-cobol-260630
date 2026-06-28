       IDENTIFICATION DIVISION.
       PROGRAM-ID. CAL-LOOKUP.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CALENDAR-FILE
               ASSIGN TO "/workspace/subsystems/01-calendar/data/calendar.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS CAL-REC-DATE
               FILE STATUS IS WS-IDX-FS.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-calendar.cpy".

       WORKING-STORAGE SECTION.
       01  WS-IDX-FS              PIC X(2).
       01  WS-EOF-FLAG            PIC X    VALUE 'N'.
           88  WS-EOF                    VALUE 'Y'.
       01  WS-LOAD-COUNT          PIC 9(5) VALUE 0.

       COPY "ws-cal-cache.cpy".

       COPY "shared-log-api.cpy".

       LINKAGE SECTION.
       COPY "cal-api.cpy".

       PROCEDURE DIVISION USING CAL-INPUT CAL-OUTPUT.
       MAIN-LOGIC.
           MOVE 00 TO CAL-STATUS.
           MOVE SPACES TO CAL-OUTPUT-DAY-TYPE.
           MOVE SPACES TO CAL-OUTPUT-HOLIDAY-NAME.
           MOVE ZERO TO CAL-OUTPUT-NEXT-DATE.

           IF CAL-INPUT-DATE NOT NUMERIC THEN
               MOVE 08 TO CAL-STATUS
               GOBACK
           END-IF.

           IF CAL-INPUT-DATE < 20260101
              OR CAL-INPUT-DATE > 20301231 THEN
               MOVE 04 TO CAL-STATUS
               GOBACK
           END-IF.

           IF NOT WS-IS-LOADED THEN
               PERFORM LOAD-CACHE
               IF CAL-STATUS NOT = 0 THEN
                   GOBACK
               END-IF
           END-IF.

           PERFORM VARYING WS-CAL-IDX FROM 1 BY 1
                   UNTIL WS-CAL-IDX > WS-CACHE-COUNT
              IF WS-ENTRY-DATE(WS-CAL-IDX) = CAL-INPUT-DATE THEN
                  MOVE WS-ENTRY-DAY-TYPE(WS-CAL-IDX)
                      TO CAL-OUTPUT-DAY-TYPE
                  MOVE WS-ENTRY-HOLIDAY-NAME(WS-CAL-IDX)
                      TO CAL-OUTPUT-HOLIDAY-NAME
                  MOVE 00 TO CAL-STATUS
                  GOBACK
              END-IF
           END-PERFORM.

           MOVE 04 TO CAL-STATUS.
           GOBACK.

       LOAD-CACHE.
           OPEN INPUT CALENDAR-FILE.
           IF WS-IDX-FS NOT = "00" THEN
               MOVE 12 TO CAL-STATUS
               EXIT PARAGRAPH
           END-IF.

           PERFORM UNTIL WS-EOF
               READ CALENDAR-FILE NEXT RECORD
                   AT END SET WS-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO WS-CACHE-COUNT
                       IF WS-CACHE-COUNT <= 1826 THEN
                           MOVE CAL-REC-DATE
                               TO WS-ENTRY-DATE(WS-CACHE-COUNT)
                           MOVE CAL-REC-DAY-TYPE
                               TO WS-ENTRY-DAY-TYPE(WS-CACHE-COUNT)
                           MOVE CAL-REC-HOLIDAY-NAME
                               TO WS-ENTRY-HOLIDAY-NAME(WS-CACHE-COUNT)
                       END-IF
               END-READ
           END-PERFORM.

           CLOSE CALENDAR-FILE.
           MOVE 'Y' TO WS-CACHE-LOADED.

           MOVE "01-calendar" TO WS-LOG-SUBSYSTEM.
           MOVE "INFO " TO WS-LOG-LEVEL.
           STRING "CAL-LOOKUP: cache_load_complete entries="
                  WS-CACHE-COUNT
                  INTO WS-LOG-MESSAGE
           END-STRING.
           CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
