       IDENTIFICATION DIVISION.
       PROGRAM-ID. IRATE-LOOKUP.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IRATE-FILE
               ASSIGN TO "/workspace/subsystems/06-interestrate/data/interestrate.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS IR-REC-KEY
               FILE STATUS IS WS-FS.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-irate.cpy".

       WORKING-STORAGE SECTION.
       01 WS-FS PIC X(2).

       LINKAGE SECTION.
       COPY "irate-api.cpy".

       PROCEDURE DIVISION USING IRATE-INPUT IRATE-OUTPUT.
       MAIN-LOGIC.
           MOVE 0 TO IR-OUT-STATUS
           OPEN INPUT IRATE-FILE
           IF WS-FS NOT = "00" MOVE 16 TO IR-OUT-STATUS GOBACK END-IF
           MOVE IR-IN-PRODUCT   TO IR-REC-PRODUCT
           MOVE IR-IN-TIER      TO IR-REC-TIER
           MOVE IR-IN-EFFECTIVE TO IR-REC-EFF-FROM
           READ IRATE-FILE
               INVALID KEY MOVE 4 TO IR-OUT-STATUS
               NOT INVALID KEY
                   COMPUTE IR-OUT-RATE-MICRO = IR-REC-RATE * 1000000
                   MOVE IR-REC-EFF-FROM TO IR-OUT-EFF-FROM
                   MOVE IR-REC-EFF-TO   TO IR-OUT-EFF-TO
                   MOVE 0 TO IR-OUT-STATUS
           END-READ
           CLOSE IRATE-FILE
           GOBACK.
