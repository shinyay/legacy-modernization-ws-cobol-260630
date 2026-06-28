       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUST-LOAD.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUST-SEED-FILE
               ASSIGN TO "/workspace/subsystems/03-customer/data/customers-mvp.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-SEED-FS.
           SELECT CUSTOMER-FILE
               ASSIGN TO "/workspace/subsystems/03-customer/data/customer.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS CR-ID
               ALTERNATE RECORD KEY IS CR-KANA WITH DUPLICATES
               ALTERNATE RECORD KEY IS CR-PHONE WITH DUPLICATES
               FILE STATUS IS WS-IDX-FS.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-cust-seed.cpy".
       COPY "fd-customer.cpy".

       WORKING-STORAGE SECTION.
       01  WS-SEED-FS PIC X(2).
       01  WS-IDX-FS  PIC X(2).
       01  WS-EOF     PIC X VALUE 'N'. 88 EOFY VALUE 'Y'.
       01  WS-COUNT   PIC 9(5) VALUE 0.
       01  WS-DUP     PIC 9(5) VALUE 0.
       COPY "shared-log-api.cpy".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           OPEN INPUT CUST-SEED-FILE
           OPEN OUTPUT CUSTOMER-FILE
           IF WS-SEED-FS NOT = "00" OR WS-IDX-FS NOT = "00"
               MOVE 16 TO RETURN-CODE GOBACK
           END-IF

           PERFORM UNTIL EOFY
               READ CUST-SEED-FILE
                   AT END SET EOFY TO TRUE
                   NOT AT END
                       MOVE CS-ID          TO CR-ID
                       MOVE CS-KANA        TO CR-KANA
                       MOVE CS-KANJI       TO CR-KANJI
                       MOVE CS-PHONE       TO CR-PHONE
                       MOVE CS-ADDRESS     TO CR-ADDRESS
                       MOVE CS-OPENED-DATE TO CR-OPENED-DATE
                       MOVE CS-STATUS      TO CR-STATUS
                       MOVE CS-CREATED-TS  TO CR-CREATED-TS
                       MOVE CS-UPDATED-TS  TO CR-UPDATED-TS
                       MOVE CS-TIER        TO CR-TIER
                       MOVE CS-FILLER      TO CR-FILLER
                       WRITE CUST-REC
                           INVALID KEY ADD 1 TO WS-DUP
                           NOT INVALID KEY ADD 1 TO WS-COUNT
                       END-WRITE
               END-READ
           END-PERFORM

           CLOSE CUST-SEED-FILE
           CLOSE CUSTOMER-FILE

           MOVE "03-customer" TO WS-LOG-SUBSYSTEM
           MOVE "INFO " TO WS-LOG-LEVEL
           STRING "CUST-LOAD complete loaded=" WS-COUNT
                  " dups=" WS-DUP
                  INTO WS-LOG-MESSAGE END-STRING
           CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC

           IF WS-DUP > 0 MOVE 4 TO RETURN-CODE
              ELSE MOVE 0 TO RETURN-CODE END-IF
           STOP RUN.
