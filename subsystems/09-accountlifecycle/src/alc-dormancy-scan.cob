       IDENTIFICATION DIVISION.
       PROGRAM-ID. ALC-DORMANCY-SCAN.
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
       01  WS-EOF             PIC X VALUE 'N'. 88 EOFY VALUE 'Y'.
       01  WS-CD              PIC X(21).
       01  WS-CD-PARTS REDEFINES WS-CD.
           05  WS-CD-YYYY     PIC 9(4).
           05  WS-CD-MM       PIC 9(2).
           05  WS-CD-DD       PIC 9(2).
           05  WS-CD-HH       PIC 9(2).
           05  WS-CD-MI       PIC 9(2).
           05  WS-CD-SS       PIC 9(2).
       01  WS-NOW-TS          PIC 9(14).
       01  WS-CUTOFF-DATE     PIC 9(8).
       01  WS-CUTOFF-INT      PIC 9(8).
       01  WS-BD-INT          PIC 9(8).

       COPY "aud-write-api.cpy".

       LINKAGE SECTION.
       COPY "alc-api.cpy".

       PROCEDURE DIVISION USING ALC-DORMANCY-SCAN-INPUT
                                ALC-DORMANCY-SCAN-OUTPUT
                                ALC-DORMANCY-SCAN-STATUS.
       MAIN-LOGIC.
           MOVE "00" TO ALC-DORMANCY-SCAN-STATUS
           MOVE 0 TO ALC-DORMANCY-TRANSITIONED
           MOVE 0 TO ALC-DORMANCY-SKIPPED

           COMPUTE WS-BD-INT =
               FUNCTION INTEGER-OF-DATE(ALC-DORMANCY-BUSINESS-DATE)
           COMPUTE WS-CUTOFF-INT = WS-BD-INT - 730
           COMPUTE WS-CUTOFF-DATE =
               FUNCTION DATE-OF-INTEGER(WS-CUTOFF-INT)

           MOVE FUNCTION CURRENT-DATE TO WS-CD
           STRING WS-CD-YYYY WS-CD-MM WS-CD-DD
                  WS-CD-HH WS-CD-MI WS-CD-SS
                  DELIMITED BY SIZE
                  INTO WS-NOW-TS
           END-STRING

           OPEN I-O ACCOUNT-FILE
           IF WS-FS NOT = "00"
               MOVE "12" TO ALC-DORMANCY-SCAN-STATUS GOBACK
           END-IF

           MOVE LOW-VALUES TO ACCT-REC-NUMBER
           START ACCOUNT-FILE KEY >= ACCT-REC-NUMBER
               INVALID KEY
                   MOVE "04" TO ALC-DORMANCY-SCAN-STATUS
                   CLOSE ACCOUNT-FILE GOBACK
           END-START

           PERFORM UNTIL EOFY
               READ ACCOUNT-FILE NEXT
                   AT END SET EOFY TO TRUE
                   NOT AT END
                       IF ACCT-REC-STATUS = "A"
                          AND ACCT-REC-DORMANCY-DATE < WS-CUTOFF-DATE
                           PERFORM TRANSITION-TO-D
                       ELSE
                           IF ACCT-REC-STATUS = "A"
                               ADD 1 TO ALC-DORMANCY-SKIPPED
                           END-IF
                       END-IF
               END-READ
           END-PERFORM

           CLOSE ACCOUNT-FILE

           IF ALC-DORMANCY-TRANSITIONED = 0
              AND ALC-DORMANCY-SKIPPED = 0
               MOVE "04" TO ALC-DORMANCY-SCAN-STATUS
           ELSE
               MOVE "00" TO ALC-DORMANCY-SCAN-STATUS
           END-IF
           GOBACK.

       TRANSITION-TO-D.
           MOVE "D" TO ACCT-REC-STATUS
           MOVE WS-NOW-TS TO ACCT-REC-UPDATED-TS
           REWRITE ACCT-REC
           IF WS-FS = "00"
               ADD 1 TO ALC-DORMANCY-TRANSITIONED
               MOVE "09-accountlifecycle" TO WS-AUD-SUBSYSTEM
               MOVE "STATUS_CHANGED" TO WS-AUD-ACTION
               MOVE "SYSTEM" TO WS-AUD-ACTOR
               MOVE "ACCOUNT" TO WS-AUD-TARGET-TYPE
               MOVE ACCT-REC-NUMBER TO WS-AUD-TARGET-ID
               STRING '{"from":"A","to":"D","reason":"dormancy_24mo"}'
                      INTO WS-AUD-PAYLOAD-JSON END-STRING
               MOVE "W" TO WS-AUD-SEVERITY
               MOVE ALC-DORMANCY-BUSINESS-DATE TO WS-AUD-BUSINESS-DATE
               CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC
           END-IF.
