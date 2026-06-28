       IDENTIFICATION DIVISION.
       PROGRAM-ID. ALC-OPEN.
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
       01  WS-SERIAL          PIC 9(7) VALUE 9000000.
       01  WS-CANDIDATE       PIC 9(13).
       01  WS-CAND-PARTS REDEFINES WS-CANDIDATE.
           05  WS-CAND-BRANCH PIC 9(3).
           05  WS-CAND-PROD   PIC 9(3).
           05  WS-CAND-SERIAL PIC 9(7).
       01  WS-CD              PIC X(21).
       01  WS-CD-PARTS REDEFINES WS-CD.
           05  WS-CD-YYYY     PIC 9(4).
           05  WS-CD-MM       PIC 9(2).
           05  WS-CD-DD       PIC 9(2).
           05  WS-CD-HH       PIC 9(2).
           05  WS-CD-MI       PIC 9(2).
           05  WS-CD-SS       PIC 9(2).
       01  WS-NOW-TS          PIC 9(14).
       01  WS-FOUND           PIC X VALUE 'Y'.

       COPY "aud-write-api.cpy".

       LINKAGE SECTION.
       COPY "alc-api.cpy".

       PROCEDURE DIVISION USING ALC-OPEN-INPUT
                                ALC-OPEN-OUTPUT
                                ALC-OPEN-STATUS.
       MAIN-LOGIC.
           MOVE "00" TO ALC-OPEN-STATUS
           MOVE ZERO TO ALC-OPEN-ACCT-NUMBER

           IF ALC-OPEN-CUST-ID = 0 OR ALC-OPEN-PRODUCT-CODE = 0
              OR ALC-OPEN-BRANCH-CODE = 0
               MOVE "08" TO ALC-OPEN-STATUS GOBACK
           END-IF

           OPEN I-O ACCOUNT-FILE
           IF WS-FS NOT = "00"
               MOVE "12" TO ALC-OPEN-STATUS GOBACK
           END-IF

           MOVE 'Y' TO WS-FOUND
           PERFORM UNTIL WS-FOUND = 'N' OR WS-SERIAL > 9999999
               MOVE ALC-OPEN-BRANCH-CODE TO WS-CAND-BRANCH
               MOVE ALC-OPEN-PRODUCT-CODE TO WS-CAND-PROD
               MOVE WS-SERIAL TO WS-CAND-SERIAL
               MOVE WS-CANDIDATE TO ACCT-REC-NUMBER
               READ ACCOUNT-FILE
                   INVALID KEY
                       MOVE 'N' TO WS-FOUND
                   NOT INVALID KEY
                       ADD 1 TO WS-SERIAL
               END-READ
           END-PERFORM

           IF WS-FOUND = 'Y'
               MOVE "08" TO ALC-OPEN-STATUS
               CLOSE ACCOUNT-FILE GOBACK
           END-IF

           MOVE FUNCTION CURRENT-DATE TO WS-CD
           STRING WS-CD-YYYY WS-CD-MM WS-CD-DD
                  WS-CD-HH WS-CD-MI WS-CD-SS
                  DELIMITED BY SIZE
                  INTO WS-NOW-TS
           END-STRING

           MOVE WS-CANDIDATE TO ACCT-REC-NUMBER
           MOVE ALC-OPEN-CUST-ID TO ACCT-REC-CUST-ID
           MOVE ALC-OPEN-PRODUCT-CODE TO ACCT-REC-PRODUCT-CODE
           MOVE ALC-OPEN-BRANCH-CODE TO ACCT-REC-BRANCH-CODE
           MOVE ALC-OPEN-OPENED-DATE TO ACCT-REC-OPENED-DATE
           MOVE 0 TO ACCT-REC-CLOSED-DATE
           MOVE "P" TO ACCT-REC-STATUS
           MOVE ALC-OPEN-OVERDRAFT-LIMIT TO ACCT-REC-OVERDRAFT
           MOVE ALC-OPEN-TERM-DAYS TO ACCT-REC-TERM-DAYS
           MOVE ALC-OPEN-OPENED-DATE TO ACCT-REC-DORMANCY-DATE
           MOVE WS-NOW-TS TO ACCT-REC-CREATED-TS
           MOVE WS-NOW-TS TO ACCT-REC-UPDATED-TS
           MOVE SPACES TO ACCT-REC-FILLER

           WRITE ACCT-REC
               INVALID KEY
                   MOVE "12" TO ALC-OPEN-STATUS
                   CLOSE ACCOUNT-FILE GOBACK
           END-WRITE
           CLOSE ACCOUNT-FILE

           MOVE WS-CANDIDATE TO ALC-OPEN-ACCT-NUMBER

           MOVE "09-accountlifecycle" TO WS-AUD-SUBSYSTEM
           MOVE "ACCOUNT_OPENED" TO WS-AUD-ACTION
           MOVE "SYSTEM" TO WS-AUD-ACTOR
           MOVE "ACCOUNT" TO WS-AUD-TARGET-TYPE
           MOVE WS-CANDIDATE TO WS-AUD-TARGET-ID
           STRING '{"acct":"' WS-CANDIDATE
                  '","cust":"' ALC-OPEN-CUST-ID
                  '","prod":"' ALC-OPEN-PRODUCT-CODE
                  '","branch":"' ALC-OPEN-BRANCH-CODE
                  '"}'
                  INTO WS-AUD-PAYLOAD-JSON END-STRING
           MOVE "I" TO WS-AUD-SEVERITY
           MOVE ALC-OPEN-OPENED-DATE TO WS-AUD-BUSINESS-DATE
           CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC

           MOVE "00" TO ALC-OPEN-STATUS
           GOBACK.
