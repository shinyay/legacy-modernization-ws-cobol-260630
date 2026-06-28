       IDENTIFICATION DIVISION.
       PROGRAM-ID. FEE-LOAD.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT FS-SEED-FILE
               ASSIGN TO "/workspace/subsystems/07-feeschedule/data/feeschedules-mvp.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-SF.
           SELECT FS-FILE
               ASSIGN TO "/workspace/subsystems/07-feeschedule/data/feeschedule.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS FS-REC-KEY
               FILE STATUS IS WS-IF.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-fs-seed.cpy".
       COPY "fd-fs.cpy".

       WORKING-STORAGE SECTION.
       01 WS-SF PIC X(2). 01 WS-IF PIC X(2).
       01 WS-EOF PIC X VALUE 'N'. 88 EOFY VALUE 'Y'.
       01 WS-COUNT PIC 9(3) VALUE 0.

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           OPEN INPUT FS-SEED-FILE
           OPEN OUTPUT FS-FILE
           PERFORM UNTIL EOFY
               READ FS-SEED-FILE
                   AT END SET EOFY TO TRUE
                   NOT AT END
                       MOVE FSS-CATEGORY TO FS-REC-CATEGORY
                       MOVE FSS-TIER     TO FS-REC-TIER
                       MOVE FSS-EFF-FROM TO FS-REC-EFF-FROM
                       MOVE FSS-TIER-MIN TO FS-REC-TIER-MIN
                       MOVE FSS-TIER-MAX TO FS-REC-TIER-MAX
                       MOVE FSS-AMOUNT   TO FS-REC-AMOUNT
                       MOVE FSS-EFF-TO   TO FS-REC-EFF-TO
                       WRITE FS-REC
                           INVALID KEY CONTINUE
                           NOT INVALID KEY ADD 1 TO WS-COUNT
                       END-WRITE
               END-READ
           END-PERFORM
           CLOSE FS-SEED-FILE
           CLOSE FS-FILE
           DISPLAY "FEE-LOAD loaded=" WS-COUNT
           STOP RUN.
