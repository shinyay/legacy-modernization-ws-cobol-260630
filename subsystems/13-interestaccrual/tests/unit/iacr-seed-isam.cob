       IDENTIFICATION DIVISION.
       PROGRAM-ID. IACR-SEED-ISAM.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE
               ASSIGN TO "/workspace/subsystems/08-account/data/account.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE  IS RANDOM
               RECORD KEY   IS ACCT-REC-NUMBER
               ALTERNATE RECORD KEY IS ACCT-REC-CUST-ID
                   WITH DUPLICATES
               FILE STATUS  IS WS-FS.
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
       01  WS-FS                       PIC X(2).
       01  WS-IDX                      PIC 9(2).
       01  WS-INSERTED                 PIC 9(2) VALUE 0.
       01  WS-UPDATED                  PIC 9(2) VALUE 0.

       01  WS-DATA.
           05  FILLER PIC 9(13) VALUE 0010010099001.
           05  FILLER PIC 9(3)  VALUE 001.
           05  FILLER PIC X(1)  VALUE "A".
           05  FILLER PIC 9(13) VALUE 0010010099002.
           05  FILLER PIC 9(3)  VALUE 001.
           05  FILLER PIC X(1)  VALUE "D".
           05  FILLER PIC 9(13) VALUE 0010010099003.
           05  FILLER PIC 9(3)  VALUE 003.
           05  FILLER PIC X(1)  VALUE "A".
           05  FILLER PIC 9(13) VALUE 0010010099004.
           05  FILLER PIC 9(3)  VALUE 001.
           05  FILLER PIC X(1)  VALUE "P".
           05  FILLER PIC 9(13) VALUE 0010010099005.
           05  FILLER PIC 9(3)  VALUE 001.
           05  FILLER PIC X(1)  VALUE "C".
           05  FILLER PIC 9(13) VALUE 0010010099006.
           05  FILLER PIC 9(3)  VALUE 001.
           05  FILLER PIC X(1)  VALUE "S".
           05  FILLER PIC 9(13) VALUE 0010010099007.
           05  FILLER PIC 9(3)  VALUE 001.
           05  FILLER PIC X(1)  VALUE "A".
       01  WS-TABLE REDEFINES WS-DATA.
           05  WS-ENTRY OCCURS 7 TIMES.
               10  WS-T-ACCT     PIC 9(13).
               10  WS-T-PROD     PIC 9(3).
               10  WS-T-STATUS   PIC X(1).

       PROCEDURE DIVISION.
       MAIN.
           OPEN I-O ACCOUNT-FILE
           IF WS-FS NOT = "00"
               DISPLAY "[iacr-seed-isam] OPEN I-O fail fs=" WS-FS
               STOP RUN RETURNING 1
           END-IF
           PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL WS-IDX > 7
               MOVE WS-T-ACCT(WS-IDX)   TO ACCT-REC-NUMBER
               MOVE 9999000099          TO ACCT-REC-CUST-ID
               MOVE WS-T-PROD(WS-IDX)   TO ACCT-REC-PRODUCT-CODE
               MOVE 001                 TO ACCT-REC-BRANCH-CODE
               MOVE 20260101            TO ACCT-REC-OPENED-DATE
               MOVE 0                   TO ACCT-REC-CLOSED-DATE
               MOVE WS-T-STATUS(WS-IDX) TO ACCT-REC-STATUS
               MOVE 0                   TO ACCT-REC-OVERDRAFT
               MOVE 0                   TO ACCT-REC-TERM-DAYS
               MOVE 99991231            TO ACCT-REC-DORMANCY-DATE
               MOVE 20260101000000      TO ACCT-REC-CREATED-TS
               MOVE 20260101000000      TO ACCT-REC-UPDATED-TS
               MOVE SPACES              TO ACCT-REC-FILLER
               WRITE ACCT-REC
                   INVALID KEY
                       ADD 1 TO WS-UPDATED
                       REWRITE ACCT-REC
                           INVALID KEY CONTINUE
                       END-REWRITE
                   NOT INVALID KEY ADD 1 TO WS-INSERTED
               END-WRITE
           END-PERFORM
           CLOSE ACCOUNT-FILE
           DISPLAY "[iacr-seed-isam] inserted=" WS-INSERTED
                   " updated=" WS-UPDATED
           STOP RUN.
