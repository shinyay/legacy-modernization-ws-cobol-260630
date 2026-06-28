       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCT-LOOKUP-BY-CUSTOMER.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE
               ASSIGN TO "/workspace/subsystems/08-account/data/account.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS ACCT-REC-NUMBER
               ALTERNATE RECORD KEY IS ACCT-REC-CUST-ID WITH DUPLICATES
               FILE STATUS IS WS-FS.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-account.cpy".

       WORKING-STORAGE SECTION.
       01  WS-FS              PIC X(2).
       01  WS-SCAN-COUNT      PIC 9(3) VALUE 0.
       01  WS-BUF-CAP         PIC 9(3) VALUE 50.
       01  WS-I               PIC 9(3) COMP.
       01  WS-J               PIC 9(3) COMP.
       01  WS-TMP-NUMBER      PIC 9(13).
       01  WS-TMP-REC         PIC X(110).

       01  WS-LBC-SCAN-BUFFER.
           05  WS-LBC-ENTRY OCCURS 50 TIMES.
               10  WS-LBC-NUMBER  PIC 9(13).
               10  WS-LBC-REC     PIC X(110).

       LINKAGE SECTION.
       COPY "acct-api.cpy".

       PROCEDURE DIVISION USING ACCT-LOOKUP-BY-CUST-INPUT
                                ACCT-LOOKUP-BY-CUST-OUTPUT
                                ACCT-LOOKUP-BY-CUST-STATUS.
       MAIN-LOGIC.
           MOVE "00" TO ACCT-LOOKUP-BY-CUST-STATUS
           MOVE 0 TO LOOKUP-BY-CUST-COUNT
           MOVE "N" TO LOOKUP-BY-CUST-MORE
           MOVE ZERO TO LOOKUP-BY-CUST-LAST-ACCT

           IF LOOKUP-BY-CUST-MAX < 1 OR LOOKUP-BY-CUST-MAX > 20
               MOVE "08" TO ACCT-LOOKUP-BY-CUST-STATUS GOBACK
           END-IF

           OPEN INPUT ACCOUNT-FILE
           IF WS-FS NOT = "00"
               MOVE "12" TO ACCT-LOOKUP-BY-CUST-STATUS GOBACK
           END-IF

           MOVE LOOKUP-BY-CUST-CUST-ID TO ACCT-REC-CUST-ID
           START ACCOUNT-FILE KEY = ACCT-REC-CUST-ID
               INVALID KEY
                   MOVE "04" TO ACCT-LOOKUP-BY-CUST-STATUS
                   CLOSE ACCOUNT-FILE GOBACK
           END-START

           PERFORM UNTIL WS-SCAN-COUNT >= WS-BUF-CAP
               READ ACCOUNT-FILE NEXT
                   AT END EXIT PERFORM
                   NOT AT END
                       IF ACCT-REC-CUST-ID NOT = LOOKUP-BY-CUST-CUST-ID
                           EXIT PERFORM
                       END-IF
                       ADD 1 TO WS-SCAN-COUNT

       MOVE ACCT-REC-NUMBER
                            TO WS-LBC-NUMBER(WS-SCAN-COUNT)
                       MOVE ACCT-REC
                            TO WS-LBC-REC(WS-SCAN-COUNT)
               END-READ
           END-PERFORM

           CLOSE ACCOUNT-FILE

           IF WS-SCAN-COUNT = 0
               MOVE "04" TO ACCT-LOOKUP-BY-CUST-STATUS GOBACK
           END-IF

           PERFORM VARYING WS-I FROM 2 BY 1 UNTIL WS-I > WS-SCAN-COUNT
               MOVE WS-LBC-NUMBER(WS-I) TO WS-TMP-NUMBER
               MOVE WS-LBC-REC(WS-I) TO WS-TMP-REC
               MOVE WS-I TO WS-J
               PERFORM UNTIL WS-J <= 1
                              OR WS-LBC-NUMBER(WS-J - 1) <= WS-TMP-NUMBER
                   MOVE WS-LBC-NUMBER(WS-J - 1) TO WS-LBC-NUMBER(WS-J)
                   MOVE WS-LBC-REC(WS-J - 1) TO WS-LBC-REC(WS-J)
                   SUBTRACT 1 FROM WS-J
               END-PERFORM
               MOVE WS-TMP-NUMBER TO WS-LBC-NUMBER(WS-J)
               MOVE WS-TMP-REC TO WS-LBC-REC(WS-J)
           END-PERFORM

           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-SCAN-COUNT
              IF WS-LBC-NUMBER(WS-I) > LOOKUP-BY-CUST-START-AFTER
                 AND LOOKUP-BY-CUST-COUNT < LOOKUP-BY-CUST-MAX
                   ADD 1 TO LOOKUP-BY-CUST-COUNT
                   MOVE WS-LBC-REC(WS-I)
                        TO LOOKUP-BY-CUST-REC(LOOKUP-BY-CUST-COUNT)
                   MOVE WS-LBC-NUMBER(WS-I) TO LOOKUP-BY-CUST-LAST-ACCT
              END-IF
           END-PERFORM

           IF LOOKUP-BY-CUST-COUNT = LOOKUP-BY-CUST-MAX
              AND WS-LBC-NUMBER(WS-SCAN-COUNT) > LOOKUP-BY-CUST-LAST-ACCT
               MOVE "Y" TO LOOKUP-BY-CUST-MORE
           ELSE
               MOVE "N" TO LOOKUP-BY-CUST-MORE
           END-IF

           IF WS-SCAN-COUNT = WS-BUF-CAP
               MOVE "02" TO ACCT-LOOKUP-BY-CUST-STATUS
           ELSE
               MOVE "00" TO ACCT-LOOKUP-BY-CUST-STATUS
           END-IF
           GOBACK.
