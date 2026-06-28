       IDENTIFICATION DIVISION.
       PROGRAM-ID. ALC-CHANGE-STATE.
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
       01  WS-FS              PIC X(2).
       01  WS-TARGET-STATUS   PIC X(1).
       01  WS-GUARD-RC        PIC 9 VALUE 0.
       01  WS-CD              PIC X(21).
       01  WS-CD-PARTS REDEFINES WS-CD.
           05  WS-CD-YYYY     PIC 9(4).
           05  WS-CD-MM       PIC 9(2).
           05  WS-CD-DD       PIC 9(2).
           05  WS-CD-HH       PIC 9(2).
           05  WS-CD-MI       PIC 9(2).
           05  WS-CD-SS       PIC 9(2).
       01  WS-NOW-TS          PIC 9(14).

       COPY "aud-write-api.cpy".

       LINKAGE SECTION.
       COPY "alc-api.cpy".

       PROCEDURE DIVISION USING ALC-CHANGE-INPUT
                                ALC-CHANGE-OUTPUT
                                ALC-CHANGE-STATUS.
       MAIN-LOGIC.
           MOVE "00" TO ALC-CHANGE-STATUS
           MOVE SPACES TO ALC-CHANGE-FROM-STATUS
                          ALC-CHANGE-TARGET-STATUS
                          WS-TARGET-STATUS

           EVALUATE ALC-CHANGE-ACTION-CODE
               WHEN "AC"
               WHEN "CN"
               WHEN "SU"
               WHEN "LS"
               WHEN "CL"
               WHEN "FC"
                   CONTINUE
               WHEN OTHER
                   MOVE "08" TO ALC-CHANGE-STATUS GOBACK
           END-EVALUATE

           OPEN I-O ACCOUNT-FILE
           IF WS-FS NOT = "00"
               MOVE "12" TO ALC-CHANGE-STATUS GOBACK
           END-IF

           MOVE ALC-CHANGE-ACCT-NUMBER TO ACCT-REC-NUMBER
           READ ACCOUNT-FILE
               INVALID KEY
                   MOVE "04" TO ALC-CHANGE-STATUS
                   CLOSE ACCOUNT-FILE GOBACK

END-READ

           MOVE ACCT-REC-STATUS TO ALC-CHANGE-FROM-STATUS

           EVALUATE TRUE
               WHEN ALC-CHANGE-ACTION-CODE = "AC" AND ACCT-REC-STATUS = "P"
                   MOVE "A" TO WS-TARGET-STATUS
               WHEN ALC-CHANGE-ACTION-CODE = "CN" AND ACCT-REC-STATUS = "P"
                   MOVE "C" TO WS-TARGET-STATUS
               WHEN ALC-CHANGE-ACTION-CODE = "SU"
                    AND (ACCT-REC-STATUS = "A" OR ACCT-REC-STATUS = "D")
                   MOVE "S" TO WS-TARGET-STATUS
                   IF ALC-CHANGE-REASON-TEXT = SPACES
                       MOVE 8 TO WS-GUARD-RC
                   END-IF
               WHEN ALC-CHANGE-ACTION-CODE = "LS" AND ACCT-REC-STATUS = "S"
                   MOVE "A" TO WS-TARGET-STATUS
               WHEN ALC-CHANGE-ACTION-CODE = "CL"
                    AND (ACCT-REC-STATUS = "A" OR ACCT-REC-STATUS = "D")
                   MOVE "C" TO WS-TARGET-STATUS
               WHEN ALC-CHANGE-ACTION-CODE = "FC"
                    AND ACCT-REC-STATUS NOT = "C"
                   MOVE "C" TO WS-TARGET-STATUS
                   IF ALC-CHANGE-REASON-TEXT = SPACES
                       MOVE 8 TO WS-GUARD-RC
                   END-IF
               WHEN OTHER
                   MOVE "08" TO ALC-CHANGE-STATUS
                   CLOSE ACCOUNT-FILE GOBACK
           END-EVALUATE

           IF WS-GUARD-RC = 8
               MOVE "08" TO ALC-CHANGE-STATUS
               CLOSE ACCOUNT-FILE GOBACK
           END-IF

           MOVE WS-TARGET-STATUS TO ALC-CHANGE-TARGET-STATUS

           MOVE WS-TARGET-STATUS TO ACCT-REC-STATUS
           MOVE FUNCTION CURRENT-DATE TO WS-CD
           STRING WS-CD-YYYY WS-CD-MM WS-CD-DD
                  WS-CD-HH WS-CD-MI WS-CD-SS
                  DELIMITED BY SIZE
                  INTO WS-NOW-TS
           END-STRING
           MOVE WS-NOW-TS TO ACCT-REC-UPDATED-TS
           IF WS-TARGET-STATUS = "C"
               MOVE
ALC-CHANGE-BUSINESS-DATE TO ACCT-REC-CLOSED-DATE
           END-IF

           REWRITE ACCT-REC
           IF WS-FS NOT = "00"
               MOVE "12" TO ALC-CHANGE-STATUS
               CLOSE ACCOUNT-FILE GOBACK
           END-IF
           CLOSE ACCOUNT-FILE

           MOVE "09-accountlifecycle" TO WS-AUD-SUBSYSTEM
           MOVE "STATUS_CHANGED" TO WS-AUD-ACTION
           MOVE "SYSTEM" TO WS-AUD-ACTOR
           MOVE "ACCOUNT" TO WS-AUD-TARGET-TYPE
           MOVE ALC-CHANGE-ACCT-NUMBER TO WS-AUD-TARGET-ID
           STRING '{"from":"' ALC-CHANGE-FROM-STATUS
                  '","to":"' ALC-CHANGE-TARGET-STATUS
                  '","action":"' ALC-CHANGE-ACTION-CODE '"}'
                  INTO WS-AUD-PAYLOAD-JSON END-STRING
           MOVE "W" TO WS-AUD-SEVERITY
           MOVE ALC-CHANGE-BUSINESS-DATE TO WS-AUD-BUSINESS-DATE
           CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC

           MOVE "00" TO ALC-CHANGE-STATUS
           GOBACK.
