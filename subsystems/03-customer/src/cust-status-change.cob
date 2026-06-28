       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUST-STATUS-CHANGE.
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
       01  WS-OPEN-FLAG PIC X VALUE 'N'.
       COPY "aud-write-api.cpy".

       LINKAGE SECTION.
       01  CSC-INPUT.
           05  CSC-ID              PIC 9(10).
           05  CSC-NEW-STATUS      PIC X(1).
           05  CSC-BUSINESS-DATE   PIC 9(8).
       01  CSC-OUTPUT.
           05  CSC-OUT-STATUS      PIC 9(2).

       PROCEDURE DIVISION USING CSC-INPUT CSC-OUTPUT.
       MAIN-LOGIC.
           MOVE 0 TO CSC-OUT-STATUS
           OPEN I-O CUSTOMER-FILE
           IF WS-FS NOT = "00" MOVE 16 TO CSC-OUT-STATUS GOBACK END-IF
           MOVE CSC-ID TO CR-ID
           READ CUSTOMER-FILE
               INVALID KEY MOVE 4 TO CSC-OUT-STATUS
               NOT INVALID KEY
                   MOVE CSC-NEW-STATUS TO CR-STATUS
                   REWRITE CUST-REC
                   IF WS-FS NOT = "00"
                       MOVE 16 TO CSC-OUT-STATUS
                       CLOSE CUSTOMER-FILE GOBACK
                   END-IF

                   MOVE "03-customer" TO WS-AUD-SUBSYSTEM
                   MOVE "CUST_STATUS_CHANGED" TO WS-AUD-ACTION
                   MOVE "SYSTEM" TO WS-AUD-ACTOR
                   MOVE "CUSTOMER" TO WS-AUD-TARGET-TYPE
                   MOVE CR-ID TO WS-AUD-TARGET-ID
                   STRING '{"id":"' CR-ID
                          '","new_status":"' CSC-NEW-STATUS '"}'
                          INTO WS-AUD-PAYLOAD-JSON END-STRING
                   MOVE "I" TO WS-AUD-SEVERITY
                   MOVE CSC-BUSINESS-DATE TO WS-AUD-BUSINESS-DATE
                   CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC

                   MOVE 0 TO CSC-OUT-STATUS
           END-READ
           CLOSE CUSTOMER-FILE
           GOBACK.
