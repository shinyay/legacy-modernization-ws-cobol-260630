       IDENTIFICATION DIVISION.
       PROGRAM-ID. IRATE-LOAD.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IR-SEED-FILE
               ASSIGN TO "/workspace/subsystems/06-interestrate/data/interestrates-mvp.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-SEED-FS.
           SELECT IRATE-FILE
               ASSIGN TO "/workspace/subsystems/06-interestrate/data/interestrate.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS IR-REC-KEY
               FILE STATUS IS WS-IDX-FS.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-ir-seed.cpy".
       COPY "fd-irate.cpy".

       WORKING-STORAGE SECTION.
       01 WS-SEED-FS PIC X(2).
       01 WS-IDX-FS  PIC X(2).
       01 WS-EOF     PIC X VALUE 'N'. 88 EOFY VALUE 'Y'.
       01 WS-COUNT   PIC 9(3) VALUE 0.
       01 WS-READCNT PIC 9(3) VALUE 0.
       01 WS-DUPCNT  PIC 9(3) VALUE 0.

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           OPEN INPUT IR-SEED-FILE
           OPEN OUTPUT IRATE-FILE
           PERFORM UNTIL EOFY
               READ IR-SEED-FILE
                   AT END SET EOFY TO TRUE
                   NOT AT END
                       ADD 1 TO WS-READCNT
                       MOVE IS-PRODUCT  TO IR-REC-PRODUCT
                       MOVE IS-TIER     TO IR-REC-TIER
                       MOVE IS-EFF-FROM TO IR-REC-EFF-FROM
                       MOVE IS-TIER-MIN TO IR-REC-TIER-MIN
                       MOVE IS-TIER-MAX TO IR-REC-TIER-MAX
                       MOVE IS-RATE     TO IR-REC-RATE
                       MOVE IS-EFF-TO   TO IR-REC-EFF-TO
                       MOVE IS-FILLER   TO IR-REC-FILLER
                       WRITE IR-REC
                           INVALID KEY ADD 1 TO WS-DUPCNT
                           NOT INVALID KEY ADD 1 TO WS-COUNT
                       END-WRITE
               END-READ
           END-PERFORM
           CLOSE IR-SEED-FILE
           CLOSE IRATE-FILE
           DISPLAY "IRATE-LOAD read=" WS-READCNT
                   " written=" WS-COUNT
                   " dups=" WS-DUPCNT
                   " fs=" WS-SEED-FS
           STOP RUN.
