       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCT-LOAD.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-SEED-FILE
               ASSIGN TO "/workspace/subsystems/08-account/data/accounts-mvp.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-SEED-FS.
           SELECT ACCOUNT-FILE
               ASSIGN TO "/workspace/subsystems/08-account/data/account.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS ACCT-REC-NUMBER
               ALTERNATE RECORD KEY IS ACCT-REC-CUST-ID WITH DUPLICATES
               FILE STATUS IS WS-IDX-FS.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-acct-seed.cpy".
       COPY "fd-account.cpy".

       WORKING-STORAGE SECTION.
       01  WS-SEED-FS  PIC X(2).
       01  WS-IDX-FS   PIC X(2).
       01  WS-EOF      PIC X VALUE 'N'. 88 EOFY VALUE 'Y'.
       01  WS-COUNT    PIC 9(5) VALUE 0.
       01  WS-DUP      PIC 9(5) VALUE 0.

       COPY "shared-log-api.cpy".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           OPEN INPUT ACCT-SEED-FILE
           OPEN OUTPUT ACCOUNT-FILE
           IF WS-SEED-FS NOT = "00" OR WS-IDX-FS NOT = "00"
               MOVE 12 TO RETURN-CODE GOBACK
           END-IF

           PERFORM UNTIL EOFY
               READ ACCT-SEED-FILE
                   AT END SET EOFY TO TRUE
                   NOT AT END
                       PERFORM COPY-FIELDS
                       WRITE ACCT-REC INVALID KEY
                           ADD 1 TO WS-DUP
                       NOT INVALID KEY
                           ADD 1 TO WS-COUNT
                       END-WRITE
               END-READ
           END-PERFORM

           CLOSE ACCT-SEED-FILE
           CLOSE ACCOUNT-FILE

           MOVE "08-account" TO WS-LOG-SUBSYSTEM
           MOVE "INFO " TO WS-LOG-LEVEL
           STRING "ACCT-LOAD complete loaded=" WS-COUNT
                  " dups=" WS-DUP
                  INTO WS-LOG-MESSAGE END-STRING
           CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC

           IF WS-DUP > 0 MOVE 4 TO RETURN-CODE
              ELSE MOVE 0 TO RETURN-CODE END-IF
           STOP RUN.

       COPY-FIELDS.
           MOVE AS-NUMBER         TO ACCT-REC-NUMBER
           MOVE AS-CUST-ID        TO ACCT-REC-CUST-ID
           MOVE AS-PRODUCT-CODE   TO ACCT-REC-PRODUCT-CODE
           MOVE AS-BRANCH-CODE    TO ACCT-REC-BRANCH-CODE
           MOVE AS-OPENED-DATE    TO ACCT-REC-OPENED-DATE
           MOVE AS-CLOSED-DATE    TO ACCT-REC-CLOSED-DATE
           MOVE AS-STATUS         TO ACCT-REC-STATUS
           MOVE AS-OVERDRAFT      TO ACCT-REC-OVERDRAFT
           MOVE AS-TERM-DAYS      TO ACCT-REC-TERM-DAYS
           MOVE AS-DORMANCY-DATE  TO ACCT-REC-DORMANCY-DATE
           MOVE AS-CREATED-TS     TO ACCT-REC-CREATED-TS
           MOVE AS-UPDATED-TS     TO ACCT-REC-UPDATED-TS
           MOVE AS-FILLER         TO ACCT-REC-FILLER.
