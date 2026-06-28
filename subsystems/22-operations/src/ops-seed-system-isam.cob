       IDENTIFICATION DIVISION.
       PROGRAM-ID. OPS-SEED-SYSTEM-ISAM.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE
               ASSIGN TO "/workspace/subsystems/08-account/data/account.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS ACCT-REC-NUMBER
               ALTERNATE RECORD KEY IS ACCT-REC-CUST-ID WITH DUPLICATES
               FILE STATUS IS WS-FS.

       DATA DIVISION.
       FILE SECTION.
       FD  ACCOUNT-FILE.
       01  ACCT-REC.
           05  ACCT-REC-NUMBER         PIC 9(13).
           05  ACCT-REC-CUST-ID        PIC 9(10).
           05  ACCT-REC-PRODUCT-CODE   PIC 9(3).
           05  ACCT-REC-BRANCH-CODE    PIC 9(3).
           05  ACCT-REC-OPENED-DATE    PIC 9(8).
           05  ACCT-REC-CLOSED-DATE    PIC 9(8).
           05  ACCT-REC-STATUS         PIC X(1).
           05  ACCT-REC-OVERDRAFT      PIC S9(15) COMP-3.
           05  ACCT-REC-TERM-DAYS      PIC 9(4).
           05  ACCT-REC-DORMANCY-DATE  PIC 9(8).
           05  ACCT-REC-CREATED-TS     PIC 9(14).
           05  ACCT-REC-UPDATED-TS     PIC 9(14).
           05  ACCT-REC-FILLER         PIC X(16).

       WORKING-STORAGE SECTION.
       01  WS-FS                   PIC X(2).
       01  WS-INSERTED             PIC 9(2) VALUE 0.
       01  WS-EXISTED              PIC 9(2) VALUE 0.
       01  WS-IDX                  PIC 9(2).

       01  WS-ACCT-LIST.
           05  FILLER              PIC 9(13) VALUE 0010010000001.
           05  FILLER              PIC 9(13) VALUE 0010010000002.
           05  FILLER              PIC 9(13) VALUE 0010010000003.
           05  FILLER              PIC 9(13) VALUE 0010010000004.
       01  WS-ACCT-TABLE REDEFINES WS-ACCT-LIST.
           05  WS-ACCT OCCURS 4 TIMES PIC 9(13).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "[ops-seed-isam] start"
           OPEN I-O ACCOUNT-FILE
           IF WS-FS = "35"
               DISPLAY "[ops-seed-isam] account.idx not present;"
                       " bootstrapping empty indexed file"
               OPEN OUTPUT ACCOUNT-FILE
               IF WS-FS NOT = "00"
                   DISPLAY "[ops-seed-isam] OPEN OUTPUT failed fs="
                           WS-FS
                   STOP RUN RETURNING 1
               END-IF
               CLOSE ACCOUNT-FILE
               OPEN I-O ACCOUNT-FILE
           END-IF
           IF WS-FS NOT = "00"
               DISPLAY "[ops-seed-isam] OPEN I-O failed fs=" WS-FS
               STOP RUN RETURNING 1
           END-IF
           PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL WS-IDX > 4
               MOVE WS-ACCT(WS-IDX) TO ACCT-REC-NUMBER
               MOVE 0000000001    TO ACCT-REC-CUST-ID
               MOVE 001           TO ACCT-REC-PRODUCT-CODE
               MOVE 001           TO ACCT-REC-BRANCH-CODE
               MOVE 20260101      TO ACCT-REC-OPENED-DATE
               MOVE 0             TO ACCT-REC-CLOSED-DATE
               MOVE "A"           TO ACCT-REC-STATUS
               MOVE 0             TO ACCT-REC-OVERDRAFT
               MOVE 0             TO ACCT-REC-TERM-DAYS
               MOVE 99991231      TO ACCT-REC-DORMANCY-DATE
               MOVE 20260101000000 TO ACCT-REC-CREATED-TS
               MOVE 20260101000000 TO ACCT-REC-UPDATED-TS
               MOVE SPACES        TO ACCT-REC-FILLER
               WRITE ACCT-REC
                   INVALID KEY
                       ADD 1 TO WS-EXISTED
                       REWRITE ACCT-REC
                           INVALID KEY CONTINUE
                       END-REWRITE
                   NOT INVALID KEY
                       ADD 1 TO WS-INSERTED
               END-WRITE
           END-PERFORM
           CLOSE ACCOUNT-FILE
           DISPLAY "[ops-seed-isam] done inserted="
                   WS-INSERTED " existed=" WS-EXISTED
           STOP RUN.

       END PROGRAM OPS-SEED-SYSTEM-ISAM.
