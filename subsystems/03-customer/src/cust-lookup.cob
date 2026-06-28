       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUST-LOOKUP.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUSTOMER-FILE
               ASSIGN TO "/workspace/subsystems/03-customer/data/customer.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS CR-ID
               ALTERNATE RECORD KEY IS CR-KANA WITH DUPLICATES
               ALTERNATE RECORD KEY IS CR-PHONE WITH DUPLICATES
               FILE STATUS IS WS-FS.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-customer.cpy".

       WORKING-STORAGE SECTION.
       01  WS-FS  PIC X(2).

       LINKAGE SECTION.
       COPY "cust-api.cpy".

       PROCEDURE DIVISION USING CUST-INPUT CUST-OUTPUT.
       MAIN-LOGIC.
           MOVE 0 TO CUST-OUT-STATUS
           OPEN INPUT CUSTOMER-FILE
           IF WS-FS NOT = "00" MOVE 16 TO CUST-OUT-STATUS GOBACK END-IF

           MOVE CUST-IN-ID TO CR-ID
           READ CUSTOMER-FILE
               INVALID KEY MOVE 4 TO CUST-OUT-STATUS
               NOT INVALID KEY
                   MOVE CR-ID         TO CUST-OUT-ID
                   MOVE CR-KANA       TO CUST-OUT-KANA
                   MOVE CR-KANJI      TO CUST-OUT-KANJI
                   MOVE CR-PHONE      TO CUST-OUT-PHONE
                   MOVE CR-ADDRESS    TO CUST-OUT-ADDRESS
                   MOVE CR-OPENED-DATE TO CUST-OUT-OPENED
                   MOVE CR-STATUS     TO CUST-OUT-STATUS-CODE
                   MOVE 0 TO CUST-OUT-STATUS
           END-READ

           CLOSE CUSTOMER-FILE
           GOBACK.
