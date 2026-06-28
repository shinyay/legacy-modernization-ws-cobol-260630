       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUST-LIST-ALL.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUSTOMER-FILE
               ASSIGN TO "/workspace/subsystems/03-customer/data/customer.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CR-ID
               ALTERNATE RECORD KEY IS CR-KANA WITH DUPLICATES
               ALTERNATE RECORD KEY IS CR-PHONE WITH DUPLICATES
               FILE STATUS IS WS-FS.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-customer.cpy".

       WORKING-STORAGE SECTION.
       01  WS-FS         PIC X(2).
       01  WS-OPEN-FLAG  PIC X VALUE 'N'.

       LINKAGE SECTION.
       COPY "cust-api.cpy".

       PROCEDURE DIVISION USING CUST-INPUT CUST-OUTPUT.
       MAIN-LOGIC.
           MOVE 0 TO CUST-OUT-STATUS

           IF WS-OPEN-FLAG = 'N'
               OPEN INPUT CUSTOMER-FILE
               IF WS-FS NOT = "00" MOVE 16 TO CUST-OUT-STATUS GOBACK END-IF
               MOVE 'Y' TO WS-OPEN-FLAG
           END-IF

           IF CUST-IN-OP = "A"
               MOVE LOW-VALUES TO CR-ID
               START CUSTOMER-FILE KEY >= CR-ID
                   INVALID KEY MOVE 10 TO CUST-OUT-STATUS GOBACK
               END-START
           END-IF

           READ CUSTOMER-FILE NEXT
               AT END MOVE 10 TO CUST-OUT-STATUS GOBACK
               NOT AT END
                   MOVE CR-ID         TO CUST-OUT-ID
                   MOVE CR-KANA       TO CUST-OUT-KANA
                   MOVE CR-KANJI      TO CUST-OUT-KANJI
                   MOVE CR-PHONE      TO CUST-OUT-PHONE
                   MOVE CR-ADDRESS    TO CUST-OUT-ADDRESS
                   MOVE CR-STATUS     TO CUST-OUT-STATUS-CODE
                   MOVE 0 TO CUST-OUT-STATUS
           END-READ
           GOBACK.
