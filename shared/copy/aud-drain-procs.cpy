       DRAIN-AUDIT-OUTBOX.
           MOVE SPACES TO WS-DRAIN-ENV-VAL
           ACCEPT WS-DRAIN-ENV-VAL
               FROM ENVIRONMENT 'AUD_DRAIN_SUPPRESS'
           IF FUNCTION UPPER-CASE(FUNCTION TRIM(WS-DRAIN-ENV-VAL))
              = "YES"
               EXIT PARAGRAPH
           END-IF
           MOVE SPACES TO WS-DRAIN-CMD
           MOVE SPACES TO WS-DRAIN-ENV-VAL
           ACCEPT WS-DRAIN-ENV-VAL FROM ENVIRONMENT 'AUD_DRAIN_CMD'
           IF FUNCTION TRIM(WS-DRAIN-ENV-VAL) = SPACES
               MOVE WS-DRAIN-DEFAULT-CMD TO WS-DRAIN-CMD
           ELSE
               MOVE WS-DRAIN-ENV-VAL TO WS-DRAIN-CMD
           END-IF
           CALL "SYSTEM" USING WS-DRAIN-CMD
               ON EXCEPTION
                   CONTINUE
           END-CALL
           MOVE RETURN-CODE TO WS-DRAIN-RAW-RC
           DIVIDE WS-DRAIN-RAW-RC BY 256 GIVING WS-DRAIN-EXIT
           IF WS-DRAIN-EXIT NOT = 0
               DISPLAY "[aud-drain] exit=" WS-DRAIN-EXIT
                       " (audit intents left for next drain)"
                       UPON SYSERR
           END-IF.
