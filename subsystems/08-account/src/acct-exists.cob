       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCT-EXISTS.
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
       COPY "fd-account.cpy".

       WORKING-STORAGE SECTION.
       01  WS-FS  PIC X(2).

       LINKAGE SECTION.
       COPY "acct-api.cpy".

       PROCEDURE DIVISION USING ACCT-EXISTS-INPUT
                                ACCT-EXISTS-OUTPUT
                                ACCT-EXISTS-API-STATUS.
       MAIN-LOGIC.
           MOVE "00" TO ACCT-EXISTS-API-STATUS
           MOVE "N" TO ACCT-EXISTS-FOUND
           MOVE SPACES TO ACCT-EXISTS-STATUS-CODE
           MOVE ZERO TO ACCT-EXISTS-PRODUCT-CODE
           MOVE "N" TO ACCT-EXISTS-ACTIVE-FLAG
           MOVE SPACES TO ACCT-EXISTS-FILLER

           OPEN INPUT ACCOUNT-FILE
           IF WS-FS NOT = "00"
               MOVE "12" TO ACCT-EXISTS-API-STATUS GOBACK
           END-IF

           MOVE ACCT-EXISTS-NUMBER TO ACCT-REC-NUMBER
           READ ACCOUNT-FILE
               INVALID KEY
                   MOVE "N" TO ACCT-EXISTS-FOUND
                   MOVE "04" TO ACCT-EXISTS-API-STATUS
               NOT INVALID KEY
                   MOVE "Y" TO ACCT-EXISTS-FOUND
                   MOVE ACCT-REC-STATUS TO ACCT-EXISTS-STATUS-CODE
                   MOVE ACCT-REC-PRODUCT-CODE TO ACCT-EXISTS-PRODUCT-CODE
                   IF ACCT-REC-STATUS = "A"
                       MOVE "Y" TO ACCT-EXISTS-ACTIVE-FLAG
                   ELSE
                       MOVE "N" TO ACCT-EXISTS-ACTIVE-FLAG
                   END-IF
                   MOVE "00" TO ACCT-EXISTS-API-STATUS
           END-READ

           CLOSE ACCOUNT-FILE
           GOBACK.
