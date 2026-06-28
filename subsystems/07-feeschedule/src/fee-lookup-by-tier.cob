       IDENTIFICATION DIVISION.
       PROGRAM-ID. FEE-LOOKUP-BY-TIER.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT FS-FILE
               ASSIGN TO "/workspace/subsystems/07-feeschedule/data/feeschedule.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS FS-REC-KEY
               FILE STATUS IS WS-FS.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-fs.cpy".

       WORKING-STORAGE SECTION.
       01 WS-FS PIC X(2).

       LINKAGE SECTION.
       COPY "fs-api.cpy".

       PROCEDURE DIVISION USING FS-INPUT FS-OUTPUT.
       MAIN-LOGIC.
           MOVE 0 TO FS-OUT-STATUS
           OPEN INPUT FS-FILE
           IF WS-FS NOT = "00" MOVE 16 TO FS-OUT-STATUS GOBACK END-IF
           MOVE FS-IN-CATEGORY  TO FS-REC-CATEGORY
           MOVE FS-IN-TIER      TO FS-REC-TIER
           MOVE FS-IN-EFFECTIVE TO FS-REC-EFF-FROM
           READ FS-FILE
               INVALID KEY MOVE 4 TO FS-OUT-STATUS
               NOT INVALID KEY
                   MOVE FS-REC-AMOUNT TO FS-OUT-FEE-JPY
                   MOVE FS-REC-EFF-TO TO FS-OUT-EFF-TO
                   MOVE 0 TO FS-OUT-STATUS
           END-READ
           CLOSE FS-FILE
           GOBACK.
