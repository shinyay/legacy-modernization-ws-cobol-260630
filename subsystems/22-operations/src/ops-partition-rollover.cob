       IDENTIFICATION DIVISION.
       PROGRAM-ID. OPS-PARTITION-ROLLOVER.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

           COPY "audit-api.cpy".
           COPY "aud-write-api.cpy".

       01  WS-DISP                   PIC ZZZZZZZ9.

       LINKAGE SECTION.
           COPY "ops-api.cpy".

       PROCEDURE DIVISION USING OPR-INPUT OPR-OUTPUT.
       MAIN-LOGIC.
           PERFORM INIT-OUTPUT
           PERFORM EMIT-START-AUDIT
           PERFORM POPULATE-APR
           CALL "AUDIT-PARTITION-ROLLOVER" USING APR-INPUT APR-OUTPUT
               ON EXCEPTION
                   SET OPR-FATAL TO TRUE
                   PERFORM EMIT-END-AUDIT
                   GOBACK
           END-CALL
           EVALUATE APR-STATUS
               WHEN "00" SET OPR-OK TO TRUE
               WHEN OTHER SET OPR-FATAL TO TRUE
           END-EVALUATE
           MOVE APR-OUT-CREATED-COUNT   TO OPR-OUT-CREATED-COUNT
           MOVE APR-OUT-DETACHED-COUNT  TO OPR-OUT-DETACHED-COUNT
           MOVE APR-OUT-NEXT-PARTITION  TO OPR-OUT-NEXT-PARTITION
           PERFORM EMIT-END-AUDIT
           GOBACK.

       INIT-OUTPUT.
           SET OPR-OK TO TRUE
           MOVE 0 TO OPR-OUT-CREATED-COUNT
                     OPR-OUT-DETACHED-COUNT
           MOVE SPACES TO OPR-OUT-NEXT-PARTITION.

       POPULATE-APR.
           IF OPR-OPERATOR-USER = SPACES
               MOVE "ops"               TO APR-OPERATOR-USER
           ELSE
               MOVE OPR-OPERATOR-USER  TO APR-OPERATOR-USER
           END-IF
           IF OPR-RETENTION-DAYS = 0
               MOVE 30 TO APR-RETENTION-DAYS
           ELSE
               MOVE OPR-RETENTION-DAYS TO APR-RETENTION-DAYS
           END-IF
           IF OPR-DRY-RUN = "Y"
               MOVE "Y" TO APR-DRY-RUN
           ELSE
               MOVE "N" TO APR-DRY-RUN
           END-IF
           IF OPR-ENABLE-DETACH = "Y"
               MOVE "Y" TO APR-ENABLE-DETACH
           ELSE
               MOVE "N" TO APR-ENABLE-DETACH
           END-IF.

       EMIT-START-AUDIT.
           MOVE "22-operations"        TO WS-AUD-SUBSYSTEM
           MOVE "OPS_PART_ROLL_START"  TO WS-AUD-ACTION
           MOVE "SYSTEM"               TO WS-AUD-ACTOR
           MOVE "PARTITION"            TO WS-AUD-TARGET-TYPE
           MOVE "audit_log"            TO WS-AUD-TARGET-ID
           MOVE "I"                    TO WS-AUD-SEVERITY
           ACCEPT WS-AUD-BUSINESS-DATE FROM DATE YYYYMMDD
           MOVE SPACES                 TO WS-AUD-PAYLOAD-JSON
           IF OPR-ENABLE-DETACH = "Y"
               MOVE '{"detach":"Y"}'  TO WS-AUD-PAYLOAD-JSON
           ELSE
               MOVE '{"detach":"N"}'  TO WS-AUD-PAYLOAD-JSON
           END-IF
           CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC
               ON EXCEPTION CONTINUE
           END-CALL.

       EMIT-END-AUDIT.
           MOVE "22-operations"        TO WS-AUD-SUBSYSTEM
           IF OPR-OK
               MOVE "OPS_PART_ROLL_OK" TO WS-AUD-ACTION
               MOVE "I"                TO WS-AUD-SEVERITY
           ELSE
               MOVE "OPS_PART_ROLL_FAIL" TO WS-AUD-ACTION
               MOVE "E"                  TO WS-AUD-SEVERITY
           END-IF
           MOVE "SYSTEM"               TO WS-AUD-ACTOR
           MOVE "PARTITION"            TO WS-AUD-TARGET-TYPE
           MOVE "audit_log"            TO WS-AUD-TARGET-ID
           ACCEPT WS-AUD-BUSINESS-DATE FROM DATE YYYYMMDD
           MOVE OPR-OUT-CREATED-COUNT TO WS-DISP
           MOVE SPACES                 TO WS-AUD-PAYLOAD-JSON
           STRING '{"created":' FUNCTION TRIM(WS-DISP) '}'
                  DELIMITED BY SIZE INTO WS-AUD-PAYLOAD-JSON
           CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC
               ON EXCEPTION CONTINUE
           END-CALL.

       END PROGRAM OPS-PARTITION-ROLLOVER.
