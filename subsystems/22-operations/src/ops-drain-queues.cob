       IDENTIFICATION DIVISION.
       PROGRAM-ID. OPS-DRAIN-QUEUES.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

           COPY "into-api.cpy".
           COPY "aud-write-api.cpy".

       01  WS-DISP                   PIC ZZZZZZZ9.

       LINKAGE SECTION.
           COPY "ops-api.cpy".

       PROCEDURE DIVISION USING OPD-INPUT OPD-OUTPUT.
       MAIN-LOGIC.
           PERFORM INIT-OUTPUT
           PERFORM EMIT-START-AUDIT
           PERFORM POPULATE-INTD
           CALL "INTO-DRAIN-QUEUE" USING INTD-INPUT INTD-OUTPUT
               ON EXCEPTION
                   SET OPD-FATAL TO TRUE
                   PERFORM EMIT-END-AUDIT
                   GOBACK
           END-CALL
           EVALUATE INTD-STATUS
               WHEN "00" SET OPD-OK TO TRUE
               WHEN "04" SET OPD-PARTIAL TO TRUE
               WHEN OTHER SET OPD-FATAL TO TRUE
           END-EVALUATE
           MOVE INTD-OUT-DRAINED-COUNT TO OPD-OUT-DRAINED-COUNT
           MOVE INTD-OUT-FAILED-COUNT  TO OPD-OUT-FAILED-COUNT
           PERFORM EMIT-END-AUDIT
           GOBACK.

       INIT-OUTPUT.
           SET OPD-OK TO TRUE
           MOVE 0 TO OPD-OUT-DRAINED-COUNT
                     OPD-OUT-FAILED-COUNT.

       POPULATE-INTD.
           IF OPD-SOURCE-FILENAME = SPACES
               MOVE "/data/queues/autodebit-failed.dat"
                                              TO INTD-SOURCE-FILENAME
           ELSE
               MOVE OPD-SOURCE-FILENAME      TO INTD-SOURCE-FILENAME
           END-IF
           IF OPD-MAX-RECORDS = 0
               MOVE 10000 TO INTD-MAX-RECORDS
           ELSE
               MOVE OPD-MAX-RECORDS TO INTD-MAX-RECORDS
           END-IF
           IF OPD-MODE-REAL
               MOVE "R" TO INTD-MODE
           ELSE
               MOVE "M" TO INTD-MODE
           END-IF.

       EMIT-START-AUDIT.
           MOVE "22-operations"        TO WS-AUD-SUBSYSTEM
           MOVE "OPS_DRAIN_START"      TO WS-AUD-ACTION
           MOVE "SYSTEM"               TO WS-AUD-ACTOR
           MOVE "QUEUE"                TO WS-AUD-TARGET-TYPE
           MOVE "AUTODEBIT-FAILED"     TO WS-AUD-TARGET-ID
           MOVE "I"                    TO WS-AUD-SEVERITY
           ACCEPT WS-AUD-BUSINESS-DATE FROM DATE YYYYMMDD
           MOVE SPACES                 TO WS-AUD-PAYLOAD-JSON
           MOVE '{"src":"autodebit-failed"}'
                                              TO WS-AUD-PAYLOAD-JSON
           CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC
               ON EXCEPTION CONTINUE
           END-CALL.

       EMIT-END-AUDIT.
           MOVE "22-operations"        TO WS-AUD-SUBSYSTEM
           EVALUATE TRUE
               WHEN OPD-OK
                   MOVE "OPS_DRAIN_OK"   TO WS-AUD-ACTION
                   MOVE "I"              TO WS-AUD-SEVERITY
               WHEN OPD-PARTIAL
                   MOVE "OPS_DRAIN_PART" TO WS-AUD-ACTION
                   MOVE "W"              TO WS-AUD-SEVERITY
               WHEN OTHER
                   MOVE "OPS_DRAIN_FAIL" TO WS-AUD-ACTION
                   MOVE "E"              TO WS-AUD-SEVERITY
           END-EVALUATE
           MOVE "SYSTEM"               TO WS-AUD-ACTOR
           MOVE "QUEUE"                TO WS-AUD-TARGET-TYPE
           MOVE "AUTODEBIT-FAILED"     TO WS-AUD-TARGET-ID
           ACCEPT WS-AUD-BUSINESS-DATE FROM DATE YYYYMMDD
           MOVE OPD-OUT-DRAINED-COUNT  TO WS-DISP
           MOVE SPACES                 TO WS-AUD-PAYLOAD-JSON
           STRING '{"drained":' FUNCTION TRIM(WS-DISP) '}'
                  DELIMITED BY SIZE INTO WS-AUD-PAYLOAD-JSON
           CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC
               ON EXCEPTION CONTINUE
           END-CALL.

       END PROGRAM OPS-DRAIN-QUEUES.
