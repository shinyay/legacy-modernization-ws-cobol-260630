       IDENTIFICATION DIVISION.
       PROGRAM-ID. INTO-DRAIN-QUEUE.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT FAILED-FILE
               ASSIGN TO WS-INPUT-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-IN.

       DATA DIVISION.
       FILE SECTION.
       FD  FAILED-FILE
           RECORD CONTAINS 200 CHARACTERS.
       01  FAILED-REC                PIC X(200).
       01  FAILED-REC-FIELDS REDEFINES FAILED-REC.
           05  FF-INSTRUCTION-ID     PIC X(20).
           05  FF-BUSINESS-DATE      PIC 9(8).
           05  FF-PAYER-ACCOUNT      PIC X(13).
           05  FF-PAYEE-NAME         PIC X(80).
           05  FF-AMOUNT-JPY         PIC 9(15).
           05  FF-REASON-CODE        PIC X(2).
           05  FF-REASON-EXPANDED    PIC X(20).
           05  FF-CONSECUTIVE-FAILS  PIC 9(2).
           05  FF-NEXT-ATTEMPT-DATE  PIC 9(8).
           05  FF-ATTEMPTED-AT-TS    PIC 9(14).
           05  FF-FILLER             PIC X(18).

       WORKING-STORAGE SECTION.
       01  WS-FS-IN                  PIC X(2).
       01  WS-INPUT-PATH             PIC X(120).
       01  WS-EOF-FLAG               PIC X(1) VALUE "N".
           88  WS-EOF                         VALUE "Y".
       01  WS-IN-OPEN                PIC X(1) VALUE "N".

       01  WS-CTR-READ               PIC 9(7) VALUE 0.
       01  WS-CTR-DRAINED            PIC 9(7) VALUE 0.
       01  WS-CTR-FAILED             PIC 9(7) VALUE 0.

           COPY "into-api.cpy".

           COPY "aud-write-api.cpy".

       01  WS-DISP-COUNT             PIC ZZZZZZ9.

       LINKAGE SECTION.
       01  L-INTD-INPUT.
           05  L-INTD-SOURCE-FILENAME      PIC X(120).
           05  L-INTD-MAX-RECORDS          PIC 9(7).
           05  L-INTD-MODE                 PIC X(1).

       01  L-INTD-OUTPUT.
           05  L-INTD-STATUS               PIC X(2).
           05  L-INTD-OUT-DRAINED-COUNT    PIC 9(7).
           05  L-INTD-OUT-FAILED-COUNT     PIC 9(7).
           05  L-INTD-OUT-DURATION-MS      PIC 9(7).

       PROCEDURE DIVISION USING L-INTD-INPUT L-INTD-OUTPUT.
       MAIN-LOGIC.
           PERFORM INIT-OUTPUT
           PERFORM VALIDATE-INPUT
           IF L-INTD-STATUS NOT = "00"
               GOBACK
           END-IF
           PERFORM OPEN-FAILED-FILE
           IF L-INTD-STATUS NOT = "00"
               GOBACK
           END-IF
           PERFORM EMIT-DRAIN-START-AUDIT
           PERFORM PROCESS-LOOP
           PERFORM CLOSE-FAILED-FILE
           PERFORM EMIT-DRAIN-END-AUDIT
           PERFORM POPULATE-OUTPUT
           GOBACK.

       INIT-OUTPUT.
           MOVE "00" TO L-INTD-STATUS
           MOVE 0 TO L-INTD-OUT-DRAINED-COUNT
                     L-INTD-OUT-FAILED-COUNT
                     L-INTD-OUT-DURATION-MS
                     WS-CTR-READ WS-CTR-DRAINED WS-CTR-FAILED
           MOVE "N" TO WS-EOF-FLAG WS-IN-OPEN
           IF L-INTD-MAX-RECORDS = 0
               MOVE 10000 TO L-INTD-MAX-RECORDS
           END-IF.

       VALIDATE-INPUT.
           IF L-INTD-SOURCE-FILENAME = SPACES
               MOVE "08" TO L-INTD-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE L-INTD-SOURCE-FILENAME TO WS-INPUT-PATH.

       OPEN-FAILED-FILE.
           OPEN INPUT FAILED-FILE
           EVALUATE WS-FS-IN
               WHEN "00" MOVE "Y" TO WS-IN-OPEN
               WHEN "35"
                   MOVE "Y" TO WS-EOF-FLAG
               WHEN OTHER
                   MOVE "12" TO L-INTD-STATUS
           END-EVALUATE.

       PROCESS-LOOP.
           IF WS-IN-OPEN = "N" OR WS-EOF
               EXIT PARAGRAPH
           END-IF
           PERFORM READ-ONE
           PERFORM UNTIL WS-EOF
                      OR WS-CTR-READ >= L-INTD-MAX-RECORDS
               ADD 1 TO WS-CTR-READ
               PERFORM PUBLISH-ONE-FAILURE
               PERFORM READ-ONE
           END-PERFORM.

       READ-ONE.
           READ FAILED-FILE
               AT END SET WS-EOF TO TRUE
           END-READ.

       PUBLISH-ONE-FAILURE.
           MOVE "autodebit.failed"   TO INTO-EVENT-TYPE
           MOVE FF-BUSINESS-DATE     TO INTO-BUSINESS-DATE
           MOVE SPACES               TO INTO-BATCH-ID
           MOVE SPACES               TO INTO-TXN-ID
           MOVE FF-PAYER-ACCOUNT     TO INTO-ACCOUNT
           MOVE FF-AMOUNT-JPY        TO INTO-AMOUNT-JPY
           MOVE SPACES               TO INTO-CATEGORY
           MOVE FF-REASON-CODE       TO INTO-REASON(1:2)
           MOVE SPACES               TO INTO-REASON(3:8)
           MOVE 0                    TO INTO-COUNT
           MOVE L-INTD-MODE          TO INTO-MODE
           CALL "INTO-PUBLISH-EVENT" USING INTO-INPUT INTO-OUTPUT
               ON EXCEPTION
                   ADD 1 TO WS-CTR-FAILED
                   EXIT PARAGRAPH
           END-CALL
           IF INTO-OK
               ADD 1 TO WS-CTR-DRAINED
           ELSE
               ADD 1 TO WS-CTR-FAILED
           END-IF.

       CLOSE-FAILED-FILE.
           IF WS-IN-OPEN = "Y"
               CLOSE FAILED-FILE
               MOVE "N" TO WS-IN-OPEN
           END-IF.

       EMIT-DRAIN-START-AUDIT.
           MOVE "20-integrationout"  TO WS-AUD-SUBSYSTEM
           MOVE "MQ_DRAIN_START"     TO WS-AUD-ACTION
           MOVE "SYSTEM"             TO WS-AUD-ACTOR
           MOVE "QUEUE"              TO WS-AUD-TARGET-TYPE
           MOVE "AUTODEBIT-FAILED"   TO WS-AUD-TARGET-ID
           MOVE "I"                  TO WS-AUD-SEVERITY
           ACCEPT WS-AUD-BUSINESS-DATE FROM DATE YYYYMMDD
           MOVE SPACES               TO WS-AUD-PAYLOAD-JSON
           MOVE '{"source":"autodebit-failed"}'
                                              TO WS-AUD-PAYLOAD-JSON
           CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC
               ON EXCEPTION CONTINUE
           END-CALL.

       EMIT-DRAIN-END-AUDIT.
           MOVE "20-integrationout"  TO WS-AUD-SUBSYSTEM
           IF WS-CTR-FAILED > 0
               MOVE "MQ_DRAIN_PARTIAL" TO WS-AUD-ACTION
               MOVE "W"                TO WS-AUD-SEVERITY
           ELSE
               MOVE "MQ_DRAIN_COMPLETE" TO WS-AUD-ACTION
               MOVE "I"                 TO WS-AUD-SEVERITY
           END-IF
           MOVE "SYSTEM"             TO WS-AUD-ACTOR
           MOVE "QUEUE"              TO WS-AUD-TARGET-TYPE
           MOVE "AUTODEBIT-FAILED"   TO WS-AUD-TARGET-ID
           ACCEPT WS-AUD-BUSINESS-DATE FROM DATE YYYYMMDD
           MOVE SPACES               TO WS-AUD-PAYLOAD-JSON
           MOVE WS-CTR-DRAINED       TO WS-DISP-COUNT
           STRING '{"drained":' FUNCTION TRIM(WS-DISP-COUNT)
                  DELIMITED BY SIZE INTO WS-AUD-PAYLOAD-JSON
           CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC
               ON EXCEPTION CONTINUE
           END-CALL.

       POPULATE-OUTPUT.
           MOVE WS-CTR-DRAINED TO L-INTD-OUT-DRAINED-COUNT
           MOVE WS-CTR-FAILED  TO L-INTD-OUT-FAILED-COUNT
           IF WS-CTR-FAILED > 0
               MOVE "04" TO L-INTD-STATUS
           END-IF.

       END PROGRAM INTO-DRAIN-QUEUE.
