       IDENTIFICATION DIVISION.
       PROGRAM-ID. OPS-SEED-AUDIT.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-I             PIC 9(1).
       01  WS-ACCT-NUMBER   PIC X(13).
       COPY "aud-write-api.cpy".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "[ops-seed-audit] emit AUD-WRITE for system entities".

           MOVE "22-operations" TO WS-AUD-SUBSYSTEM
           MOVE "SEED_SYSTEM_CUST" TO WS-AUD-ACTION
           MOVE "SYSTEM" TO WS-AUD-ACTOR
           MOVE "CUSTOMER" TO WS-AUD-TARGET-TYPE
           MOVE "0000000001" TO WS-AUD-TARGET-ID
           MOVE '{"cust_id":"0000000001"}' TO WS-AUD-PAYLOAD-JSON
           MOVE "I" TO WS-AUD-SEVERITY
           MOVE 20260601 TO WS-AUD-BUSINESS-DATE
           CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC
           DISPLAY "  SEED_SYSTEM_CUST emitted rc=" WS-AUD-RC

           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 4
               STRING "001001000000" WS-I
                      DELIMITED BY SIZE INTO WS-ACCT-NUMBER
               END-STRING
               MOVE "22-operations" TO WS-AUD-SUBSYSTEM
               MOVE "SEED_SYSTEM_ACCT" TO WS-AUD-ACTION
               MOVE "SYSTEM" TO WS-AUD-ACTOR
               MOVE "ACCOUNT" TO WS-AUD-TARGET-TYPE
               MOVE WS-ACCT-NUMBER TO WS-AUD-TARGET-ID
               STRING '{"acct":"' WS-ACCT-NUMBER '"}'
                      INTO WS-AUD-PAYLOAD-JSON END-STRING
               MOVE "I" TO WS-AUD-SEVERITY
               MOVE 20260601 TO WS-AUD-BUSINESS-DATE
               CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC
               DISPLAY "  SEED_SYSTEM_ACCT " WS-ACCT-NUMBER
                       " emitted rc=" WS-AUD-RC
           END-PERFORM

           DISPLAY "[ops-seed-audit] complete"
           STOP RUN.
