       IDENTIFICATION DIVISION.
       PROGRAM-ID. CON-AUDIT-DEMO.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-BDATE-X       PIC X(8)  VALUE "20260612".
       01  WS-BDATE-N       PIC 9(8).
       COPY "aud-write-api.cpy".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           ACCEPT WS-BDATE-X FROM ENVIRONMENT "DEMO_AUDIT_BDATE"
           IF WS-BDATE-X IS NOT NUMERIC
               MOVE "20260612" TO WS-BDATE-X
           END-IF
           MOVE WS-BDATE-X TO WS-BDATE-N
           DISPLAY "[con-audit-demo] seeding I/W/E/C on " WS-BDATE-X

           MOVE "I"                      TO WS-AUD-SEVERITY
           MOVE "DEMO_TXN_POSTED"        TO WS-AUD-ACTION
           MOVE "TXN"                    TO WS-AUD-TARGET-TYPE
           MOVE "DEMO00000000000001"     TO WS-AUD-TARGET-ID
           PERFORM EMIT-ONE

           MOVE "W"                      TO WS-AUD-SEVERITY
           MOVE "DEMO_RECON_DEFERRED"    TO WS-AUD-ACTION
           MOVE "TXN"                    TO WS-AUD-TARGET-TYPE
           MOVE "DEMO00000000000002"     TO WS-AUD-TARGET-ID
           PERFORM EMIT-ONE

           MOVE "E"                      TO WS-AUD-SEVERITY
           MOVE "DEMO_VALIDATE_REJECTED" TO WS-AUD-ACTION
           MOVE "TXN"                    TO WS-AUD-TARGET-TYPE
           MOVE "DEMO00000000000003"     TO WS-AUD-TARGET-ID
           PERFORM EMIT-ONE

           MOVE "C"                      TO WS-AUD-SEVERITY
           MOVE "DEMO_BALANCE_BREACH"    TO WS-AUD-ACTION
           MOVE "BATCH"                  TO WS-AUD-TARGET-TYPE
           MOVE "DEMO-BMON-RUN"          TO WS-AUD-TARGET-ID
           PERFORM EMIT-ONE

           DISPLAY "[con-audit-demo] complete"
           STOP RUN.

       EMIT-ONE.
           MOVE "12-txnpost"   TO WS-AUD-SUBSYSTEM
           MOVE "CONSOLE-DEMO" TO WS-AUD-ACTOR
           MOVE WS-BDATE-N     TO WS-AUD-BUSINESS-DATE
           MOVE '{"demo":true,"purpose":"AUDT severity colour"}'
               TO WS-AUD-PAYLOAD-JSON
           CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC
           DISPLAY "  sev=" WS-AUD-SEVERITY
                   " action=" FUNCTION TRIM(WS-AUD-ACTION)
                   " rc=" WS-AUD-RC.
