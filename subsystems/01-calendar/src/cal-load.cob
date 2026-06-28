       IDENTIFICATION DIVISION.
       PROGRAM-ID. CAL-LOAD.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CAL-SEED-FILE
               ASSIGN TO "/workspace/subsystems/01-calendar/data/calendar-seed.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-SEED-FS.

           SELECT CALENDAR-FILE
               ASSIGN TO "/workspace/subsystems/01-calendar/data/calendar.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS CAL-REC-DATE
               FILE STATUS IS WS-IDX-FS.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-cal-seed.cpy".
       COPY "fd-calendar.cpy".

       WORKING-STORAGE SECTION.
       01  WS-SEED-FS              PIC X(2).
       01  WS-IDX-FS               PIC X(2).
       01  WS-EOF-FLAG             PIC X    VALUE 'N'.
           88  WS-EOF                     VALUE 'Y'.
       01  WS-READ-COUNT           PIC 9(5) VALUE 0.
       01  WS-WRITE-COUNT          PIC 9(5) VALUE 0.
       01  WS-DUP-COUNT            PIC 9(5) VALUE 0.
       01  WS-ERR-COUNT            PIC 9(5) VALUE 0.

       COPY "shared-log-api.cpy".
       01  WS-LOG-TMP              PIC X(500).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           PERFORM LOG-START.
           PERFORM OPEN-FILES.
           IF WS-SEED-FS NOT = "00" OR WS-IDX-FS NOT = "00" THEN
               PERFORM LOG-FATAL
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF.

           PERFORM UNTIL WS-EOF
               READ CAL-SEED-FILE
                   AT END SET WS-EOF TO TRUE
                   NOT AT END
                       ADD 1 TO WS-READ-COUNT
                       PERFORM WRITE-CAL-RECORD
               END-READ
           END-PERFORM.

           PERFORM CLOSE-FILES.
           PERFORM LOG-COMPLETE.

           EVALUATE TRUE
               WHEN WS-DUP-COUNT > 0
                   MOVE 4 TO RETURN-CODE
               WHEN WS-ERR-COUNT > 0
                   MOVE 12 TO RETURN-CODE
               WHEN OTHER
                   MOVE 0 TO RETURN-CODE
           END-EVALUATE.

           STOP RUN.

       OPEN-FILES.
           OPEN INPUT CAL-SEED-FILE.
           OPEN OUTPUT CALENDAR-FILE.

       CLOSE-FILES.
           CLOSE CAL-SEED-FILE.
           CLOSE CALENDAR-FILE.

       WRITE-CAL-RECORD.
           MOVE SD-DATE         TO CAL-REC-DATE.
           MOVE SD-DAY-TYPE     TO CAL-REC-DAY-TYPE.
           MOVE SD-HOLIDAY-NAME TO CAL-REC-HOLIDAY-NAME.
           MOVE SD-FILLER       TO CAL-REC-FILLER.
           WRITE CAL-REC INVALID KEY
               ADD 1 TO WS-DUP-COUNT
               MOVE "01-calendar" TO WS-LOG-SUBSYSTEM
               MOVE "WARN " TO WS-LOG-LEVEL
               STRING "CAL-LOAD duplicate date skipped date="
                      SD-DATE
                      INTO WS-LOG-MESSAGE
               END-STRING
               CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC
           NOT INVALID KEY
               ADD 1 TO WS-WRITE-COUNT
           END-WRITE.

       LOG-START.
           MOVE "01-calendar" TO WS-LOG-SUBSYSTEM.
           MOVE "INFO " TO WS-LOG-LEVEL.
           MOVE "CAL-LOAD: load_start" TO WS-LOG-MESSAGE.
           CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.

       LOG-COMPLETE.
           MOVE "01-calendar" TO WS-LOG-SUBSYSTEM.
           MOVE "INFO " TO WS-LOG-LEVEL.
           STRING "CAL-LOAD: load_complete read=" WS-READ-COUNT
                  " written=" WS-WRITE-COUNT
                  " duplicates=" WS-DUP-COUNT
                  INTO WS-LOG-MESSAGE
           END-STRING.
           CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.

       LOG-FATAL.
           MOVE "01-calendar" TO WS-LOG-SUBSYSTEM.
           MOVE "ERROR" TO WS-LOG-LEVEL.
           STRING "CAL-LOAD FATAL: seed-fs=" WS-SEED-FS
                  " idx-fs=" WS-IDX-FS
                  INTO WS-LOG-MESSAGE
           END-STRING.
           CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
