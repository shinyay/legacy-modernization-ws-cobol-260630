       IDENTIFICATION DIVISION.
       PROGRAM-ID. INTO-PUBLISH-EVENT.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT MOCK-OUT-FILE
               ASSIGN TO WS-MOCK-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-MOCK.
           SELECT UUID-FILE
               ASSIGN TO "/proc/sys/kernel/random/uuid"
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-UUID.

       DATA DIVISION.
       FILE SECTION.
       FD  MOCK-OUT-FILE.
       01  MOCK-OUT-LINE             PIC X(4096).
       FD  UUID-FILE.
       01  UUID-IN-LINE              PIC X(64).

       WORKING-STORAGE SECTION.

       01  WS-FS-MOCK                PIC X(2).
       01  WS-FS-UUID                PIC X(2).
       01  WS-MOCK-PATH              PIC X(120) VALUE
           "/tmp/mq-mock-out.dat".

       01  WS-BROKER-HOST            PIC X(64) VALUE "rabbitmq".
       01  WS-BROKER-USER            PIC X(32) VALUE "cobol".
       01  WS-BROKER-PASS            PIC X(32) VALUE "cobol".
       01  WS-BROKER-QUEUE           PIC X(64) VALUE "pb.events".
       01  WS-BROKER-PORT            PIC S9(9) COMP-5 VALUE 5672.
       01  WS-BROKER-BODY-LEN        PIC S9(4) COMP-5 VALUE 0.

       01  WS-MOCK-FLAG              PIC X(1) VALUE "N".
           88  WS-MOCK-ON                       VALUE "Y".

       01  WS-ENVELOPE-JSON          PIC X(4096).
       01  WS-PAYLOAD-JSON           PIC X(2048).
       01  WS-EVENT-ID               PIC X(36).
       01  WS-TIMESTAMP-ISO          PIC X(20).
       01  WS-POINTER                PIC 9(4).

       01  WS-DATE-CURRENT.
           05  WS-DC-YEAR             PIC 9(4).
           05  WS-DC-MONTH            PIC 9(2).
           05  WS-DC-DAY              PIC 9(2).
           05  WS-DC-HOUR             PIC 9(2).
           05  WS-DC-MIN              PIC 9(2).
           05  WS-DC-SEC              PIC 9(2).
       01  WS-DATE-FROM-FUNCTION     PIC X(21).

       01  WS-AMT-DISP               PIC ZZZZZZZZZZZZZZ9.
       01  WS-COUNT-DISP             PIC ZZZZZZZZZ9.
       01  WS-DATE-DISP              PIC 9(8).

       01  WS-RETRY-COUNT            PIC 9(1) VALUE 0.
       01  WS-PUBLISH-RC             PIC S9(9) COMP-5 VALUE 0.
       01  WS-RETRY-MAX              PIC 9(1) VALUE 3.

           COPY "aud-write-api.cpy".

       01  WS-START-TS               PIC 9(14).
       01  WS-END-TS                 PIC 9(14).

       LINKAGE SECTION.
           COPY "into-api.cpy".

       PROCEDURE DIVISION USING INTO-INPUT INTO-OUTPUT.
       MAIN-LOGIC.
           PERFORM INIT-OUTPUT
           PERFORM VALIDATE-INPUT
           IF NOT INTO-OK
               GOBACK
           END-IF
           PERFORM CHECK-MOCK-MODE
           PERFORM GENERATE-UUID
           PERFORM FORMAT-TIMESTAMP
           PERFORM BUILD-PAYLOAD
           PERFORM BUILD-ENVELOPE
           PERFORM EMIT-AUDIT-START
           PERFORM PUBLISH-WITH-RETRY
           PERFORM EMIT-AUDIT-END
           PERFORM POPULATE-OUTPUT
           GOBACK.

       INIT-OUTPUT.
           SET INTO-OK TO TRUE
           MOVE SPACES TO INTO-EVENT-ID
           MOVE 0 TO INTO-DURATION-MS INTO-RETRY-COUNT
                     WS-RETRY-COUNT WS-PUBLISH-RC
           MOVE "N" TO WS-MOCK-FLAG.

       VALIDATE-INPUT.
           IF INTO-EVENT-TYPE = SPACES OR
              INTO-BUSINESS-DATE = 0
               SET INTO-INVALID-INPUT TO TRUE
               EXIT PARAGRAPH
           END-IF
           EVALUATE TRUE
               WHEN INTO-EVT-TXN-POSTED            CONTINUE
               WHEN INTO-EVT-INTEREST-POSTED       CONTINUE
               WHEN INTO-EVT-AUTODEBIT-FAILED      CONTINUE
               WHEN INTO-EVT-BATCH-COMPLETED       CONTINUE
               WHEN INTO-EVT-STATEMENT-GENERATED   CONTINUE
               WHEN OTHER
                   SET INTO-INVALID-INPUT TO TRUE
           END-EVALUATE.

       CHECK-MOCK-MODE.
           IF INTO-MODE-MOCK
               SET WS-MOCK-ON TO TRUE
               EXIT PARAGRAPH
           END-IF
           IF INTO-MODE-REAL
               MOVE "N" TO WS-MOCK-FLAG
               EXIT PARAGRAPH
           END-IF
           MOVE SPACES TO MOCK-OUT-LINE
           ACCEPT MOCK-OUT-LINE FROM ENVIRONMENT "INTO_MOCK_BROKER"
           IF MOCK-OUT-LINE(1:1) = "Y"
               SET WS-MOCK-ON TO TRUE
           END-IF.

       GENERATE-UUID.
           OPEN INPUT UUID-FILE
           IF WS-FS-UUID NOT = "00"
               MOVE "00000000-0000-4000-8000-000000000000"
                                              TO WS-EVENT-ID
               EXIT PARAGRAPH
           END-IF
           READ UUID-FILE INTO UUID-IN-LINE
               AT END CONTINUE
           END-READ
           CLOSE UUID-FILE
           MOVE UUID-IN-LINE(1:36) TO WS-EVENT-ID.

       FORMAT-TIMESTAMP.
           MOVE FUNCTION CURRENT-DATE TO WS-DATE-FROM-FUNCTION
           MOVE WS-DATE-FROM-FUNCTION(1:4)   TO WS-DC-YEAR
           MOVE WS-DATE-FROM-FUNCTION(5:2)   TO WS-DC-MONTH
           MOVE WS-DATE-FROM-FUNCTION(7:2)   TO WS-DC-DAY
           MOVE WS-DATE-FROM-FUNCTION(9:2)   TO WS-DC-HOUR
           MOVE WS-DATE-FROM-FUNCTION(11:2)  TO WS-DC-MIN
           MOVE WS-DATE-FROM-FUNCTION(13:2)  TO WS-DC-SEC
           MOVE SPACES TO WS-TIMESTAMP-ISO
           STRING WS-DC-YEAR "-" WS-DC-MONTH "-" WS-DC-DAY
                  "T" WS-DC-HOUR ":" WS-DC-MIN ":" WS-DC-SEC "Z"
                  DELIMITED BY SIZE INTO WS-TIMESTAMP-ISO.

       BUILD-PAYLOAD.
           MOVE SPACES TO WS-PAYLOAD-JSON
           EVALUATE TRUE
               WHEN INTO-EVT-TXN-POSTED
                   PERFORM BUILD-TXN-PAYLOAD
               WHEN INTO-EVT-INTEREST-POSTED
                   PERFORM BUILD-INTEREST-PAYLOAD
               WHEN INTO-EVT-AUTODEBIT-FAILED
                   PERFORM BUILD-AUTODEBIT-PAYLOAD
               WHEN INTO-EVT-BATCH-COMPLETED
                   PERFORM BUILD-BATCH-PAYLOAD
               WHEN INTO-EVT-STATEMENT-GENERATED
                   PERFORM BUILD-STATEMENT-PAYLOAD
           END-EVALUATE.

       BUILD-TXN-PAYLOAD.
           MOVE INTO-AMOUNT-JPY TO WS-AMT-DISP
           STRING '{"txnId":"' INTO-TXN-ID '"'
                  ',"account":"' INTO-ACCOUNT '"'
                  ',"category":"' INTO-CATEGORY '"'
                  ',"amountJpy":' FUNCTION TRIM(WS-AMT-DISP) '}'
                  DELIMITED BY SIZE INTO WS-PAYLOAD-JSON.

       BUILD-INTEREST-PAYLOAD.
           MOVE INTO-AMOUNT-JPY TO WS-AMT-DISP
           STRING '{"account":"' INTO-ACCOUNT '"'
                  ',"interestJpy":' FUNCTION TRIM(WS-AMT-DISP) '}'
                  DELIMITED BY SIZE INTO WS-PAYLOAD-JSON.

       BUILD-AUTODEBIT-PAYLOAD.
           MOVE INTO-AMOUNT-JPY TO WS-AMT-DISP
           STRING '{"account":"' INTO-ACCOUNT '"'
                  ',"amountJpy":' FUNCTION TRIM(WS-AMT-DISP)
                  ',"reason":"' FUNCTION TRIM(INTO-REASON) '"}'
                  DELIMITED BY SIZE INTO WS-PAYLOAD-JSON.

       BUILD-BATCH-PAYLOAD.
           MOVE INTO-COUNT TO WS-COUNT-DISP
           STRING '{"batchId":"' INTO-BATCH-ID '"'
                  ',"recordCount":' FUNCTION TRIM(WS-COUNT-DISP) '}'
                  DELIMITED BY SIZE INTO WS-PAYLOAD-JSON.

       BUILD-STATEMENT-PAYLOAD.
           MOVE INTO-COUNT TO WS-COUNT-DISP
           STRING '{"batchId":"' INTO-BATCH-ID '"'
                  ',"accountCount":' FUNCTION TRIM(WS-COUNT-DISP) '}'
                  DELIMITED BY SIZE INTO WS-PAYLOAD-JSON.

       BUILD-ENVELOPE.
           MOVE INTO-BUSINESS-DATE TO WS-DATE-DISP
           MOVE SPACES TO WS-ENVELOPE-JSON
           STRING '{"version":"1.0"'
                  ',"eventId":"' WS-EVENT-ID '"'
                  ',"eventType":"' FUNCTION TRIM(INTO-EVENT-TYPE) '"'
                  ',"businessDate":"' WS-DATE-DISP '"'
                  ',"publishedAt":"' WS-TIMESTAMP-ISO '"'
                  ',"source":"pb-core-batch"'
                  ',"payload":' FUNCTION TRIM(WS-PAYLOAD-JSON)
                  '}'
                  DELIMITED BY SIZE INTO WS-ENVELOPE-JSON
           COMPUTE WS-BROKER-BODY-LEN =
               FUNCTION LENGTH(FUNCTION TRIM(WS-ENVELOPE-JSON)).

       PUBLISH-WITH-RETRY.
           MOVE 0 TO WS-RETRY-COUNT
           PERFORM UNTIL WS-RETRY-COUNT >= WS-RETRY-MAX
               PERFORM PUBLISH-ONCE
               IF WS-PUBLISH-RC = 0
                   EXIT PERFORM
               END-IF
               ADD 1 TO WS-RETRY-COUNT
           END-PERFORM
           IF WS-PUBLISH-RC NOT = 0
               IF WS-RETRY-COUNT >= WS-RETRY-MAX
                   SET INTO-RETRY-EXHAUSTED TO TRUE
               ELSE
                   SET INTO-BROKER-FAIL TO TRUE
               END-IF
           END-IF.

       PUBLISH-ONCE.
           IF WS-MOCK-ON
               PERFORM PUBLISH-MOCK
           ELSE
               PERFORM PUBLISH-REAL
           END-IF.

       PUBLISH-MOCK.
           OPEN EXTEND MOCK-OUT-FILE
           IF WS-FS-MOCK NOT = "00"
               OPEN OUTPUT MOCK-OUT-FILE
           END-IF
           IF WS-FS-MOCK NOT = "00"
               MOVE -1 TO WS-PUBLISH-RC
               EXIT PARAGRAPH
           END-IF
           MOVE WS-ENVELOPE-JSON TO MOCK-OUT-LINE
           WRITE MOCK-OUT-LINE
           CLOSE MOCK-OUT-FILE
           MOVE 0 TO WS-PUBLISH-RC.

       PUBLISH-REAL.
           CALL "rmq_pub" USING
                BY REFERENCE WS-BROKER-HOST
                BY VALUE     WS-BROKER-PORT
                BY REFERENCE WS-BROKER-USER
                BY REFERENCE WS-BROKER-PASS
                BY REFERENCE WS-BROKER-QUEUE
                BY REFERENCE WS-ENVELOPE-JSON
                BY REFERENCE WS-BROKER-BODY-LEN
                RETURNING WS-PUBLISH-RC
               ON EXCEPTION
                   MOVE -1 TO WS-PUBLISH-RC
           END-CALL.

       EMIT-AUDIT-START.
           MOVE "20-integrationout"  TO WS-AUD-SUBSYSTEM
           MOVE "MQ_PUBLISH_START"   TO WS-AUD-ACTION
           MOVE "SYSTEM"             TO WS-AUD-ACTOR
           MOVE "EVENT"              TO WS-AUD-TARGET-TYPE
           MOVE WS-EVENT-ID(1:14)    TO WS-AUD-TARGET-ID
           MOVE "I"                  TO WS-AUD-SEVERITY
           MOVE INTO-BUSINESS-DATE   TO WS-AUD-BUSINESS-DATE
           MOVE SPACES               TO WS-AUD-PAYLOAD-JSON
           STRING '{"type":"' FUNCTION TRIM(INTO-EVENT-TYPE) '"}'
                  DELIMITED BY SIZE INTO WS-AUD-PAYLOAD-JSON
           CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC
               ON EXCEPTION CONTINUE
           END-CALL.

       EMIT-AUDIT-END.
           MOVE "20-integrationout"  TO WS-AUD-SUBSYSTEM
           IF INTO-OK
               MOVE "MQ_PUBLISH_COMPLETE" TO WS-AUD-ACTION
               MOVE "I"                   TO WS-AUD-SEVERITY
           ELSE
               MOVE "MQ_PUBLISH_FAIL"     TO WS-AUD-ACTION
               MOVE "W"                   TO WS-AUD-SEVERITY
           END-IF
           MOVE "SYSTEM"             TO WS-AUD-ACTOR
           MOVE "EVENT"              TO WS-AUD-TARGET-TYPE
           MOVE WS-EVENT-ID(1:14)    TO WS-AUD-TARGET-ID
           MOVE INTO-BUSINESS-DATE   TO WS-AUD-BUSINESS-DATE
           MOVE SPACES               TO WS-AUD-PAYLOAD-JSON
           STRING '{"retries":"' WS-RETRY-COUNT
                  '","rc":"' WS-PUBLISH-RC '"}'
                  DELIMITED BY SIZE INTO WS-AUD-PAYLOAD-JSON
           CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC
               ON EXCEPTION CONTINUE
           END-CALL.

       POPULATE-OUTPUT.
           MOVE WS-EVENT-ID    TO INTO-EVENT-ID
           MOVE WS-RETRY-COUNT TO INTO-RETRY-COUNT.

       END PROGRAM INTO-PUBLISH-EVENT.
