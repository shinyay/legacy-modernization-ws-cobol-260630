       IDENTIFICATION DIVISION.
       PROGRAM-ID. BR-LOAD.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT BR-SEED-FILE
               ASSIGN TO "/workspace/subsystems/02-branch/data/branches-mvp.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-SEED-FS.
           SELECT BRANCH-FILE
               ASSIGN TO "/workspace/subsystems/02-branch/data/branch.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS BR-REC-CODE
               ALTERNATE RECORD KEY IS BR-REC-REGION WITH DUPLICATES
               FILE STATUS IS WS-IDX-FS.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-br-seed.cpy".
       COPY "fd-branch.cpy".

       WORKING-STORAGE SECTION.
       01  WS-SEED-FS  PIC X(2).
       01  WS-IDX-FS   PIC X(2).
       01  WS-EOF      PIC X VALUE 'N'.
           88  EOF-Y          VALUE 'Y'.
       01  WS-COUNT    PIC 9(5) VALUE 0.
       01  WS-DUP      PIC 9(5) VALUE 0.
       COPY "shared-log-api.cpy".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           MOVE "02-branch" TO WS-LOG-SUBSYSTEM
           MOVE "INFO " TO WS-LOG-LEVEL
           MOVE "BR-LOAD start" TO WS-LOG-MESSAGE
           CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.

           OPEN INPUT BR-SEED-FILE
           OPEN OUTPUT BRANCH-FILE
           IF WS-SEED-FS NOT = "00" OR WS-IDX-FS NOT = "00" THEN
               MOVE 16 TO RETURN-CODE GOBACK
           END-IF

           PERFORM UNTIL EOF-Y
               READ BR-SEED-FILE
                   AT END SET EOF-Y TO TRUE
                   NOT AT END
                       MOVE BS-CODE         TO BR-REC-CODE
                       MOVE BS-NAME-KANJI   TO BR-REC-NAME-KANJI
                       MOVE BS-NAME-KANA    TO BR-REC-NAME-KANA
                       MOVE BS-REGION       TO BR-REC-REGION
                       MOVE BS-OPENED-DATE  TO BR-REC-OPENED-DATE
                       MOVE BS-STATUS       TO BR-REC-STATUS
                       MOVE BS-FILLER       TO BR-REC-FILLER
                       WRITE BR-REC INVALID KEY
                           ADD 1 TO WS-DUP
                       NOT INVALID KEY
                           ADD 1 TO WS-COUNT
                       END-WRITE
               END-READ
           END-PERFORM

           CLOSE BR-SEED-FILE
           CLOSE BRANCH-FILE

           MOVE "02-branch" TO WS-LOG-SUBSYSTEM
           MOVE "INFO " TO WS-LOG-LEVEL
           STRING "BR-LOAD complete loaded=" WS-COUNT
                  " dups=" WS-DUP
                  INTO WS-LOG-MESSAGE
           END-STRING
           CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC

           IF WS-DUP > 0
               MOVE 4 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF
           STOP RUN.
