       IDENTIFICATION DIVISION.
       PROGRAM-ID. E2E-DRIVER.
       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-ARGC                  PIC 9(2).
       01  WS-ARG                   PIC X(120).
       01  WS-STAGE                 PIC X(10).
       01  WS-RC                    PIC 9(4) VALUE 0.

           COPY "tx-val-api.cpy".

           COPY "tx-sm-api.cpy".

           COPY "tx-post-api.cpy".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           ACCEPT WS-STAGE FROM ARGUMENT-VALUE
           EVALUATE FUNCTION TRIM(WS-STAGE)
               WHEN "stage2" PERFORM DO-STAGE2
               WHEN "stage3" PERFORM DO-STAGE3
               WHEN "stage4" PERFORM DO-STAGE4
               WHEN "stage5" PERFORM DO-STAGE5
               WHEN "reverse" PERFORM DO-REVERSE
               WHEN OTHER
                   DISPLAY "[e2e-driver] unknown stage: "
                           WS-STAGE UPON SYSERR
                   STOP RUN RETURNING 1
           END-EVALUATE
           STOP RUN RETURNING WS-RC.

       DO-STAGE2.
           ACCEPT WS-ARG FROM ARGUMENT-VALUE
           MOVE WS-ARG(1:14)   TO TXVAL-IN-BATCH-ID
           ACCEPT WS-ARG FROM ARGUMENT-VALUE
           COMPUTE TXVAL-IN-BUSINESS-DATE =
               FUNCTION NUMVAL(WS-ARG)
           ACCEPT TXVAL-IN-INPUT-FILENAME FROM ARGUMENT-VALUE
           ACCEPT TXVAL-IN-VALID-FILENAME FROM ARGUMENT-VALUE
           ACCEPT TXVAL-IN-ERROR-FILENAME FROM ARGUMENT-VALUE
           ACCEPT TXVAL-IN-CHECKPOINT-FILENAME FROM ARGUMENT-VALUE
           CALL "TXVAL-VALIDATE-BATCH" USING
                TXVAL-BATCH-INPUT TXVAL-BATCH-OUTPUT
           DISPLAY "{"
                   """status"":"""    TXVAL-BATCH-STATUS ""","
                   """processed"":"   TXVAL-OUT-PROCESSED   ","
                   """validated"":"   TXVAL-OUT-VALIDATED   ","
                   """rejected"":"    TXVAL-OUT-REJECTED
                   "}"
           IF TXVAL-BATCH-STATUS = "16"
               MOVE 16 TO WS-RC
           END-IF.

       DO-STAGE3.
           ACCEPT WS-ARG FROM ARGUMENT-VALUE
           MOVE WS-ARG(1:14)   TO TXSM-SI-BATCH-ID
           ACCEPT WS-ARG FROM ARGUMENT-VALUE
           COMPUTE TXSM-SI-BUSINESS-DATE =
               FUNCTION NUMVAL(WS-ARG)
           ACCEPT TXSM-SI-INPUT-FILENAME FROM ARGUMENT-VALUE
           ACCEPT TXSM-SI-OUTPUT-FILENAME FROM ARGUMENT-VALUE
           ACCEPT TXSM-SI-CHECKPOINT-FILENAME FROM ARGUMENT-VALUE
           CALL "TXSM-SORT-BATCH" USING
                TXSM-SORT-INPUT TXSM-SORT-OUTPUT
           DISPLAY "{"
                   """status"":"""        TXSM-SO-STATUS ""","
                   """records_in"":"      TXSM-SO-RECORDS-PROCESSED ","
                   """records_sorted"":"  TXSM-SO-RECORDS-SORTED ","
                   """amount_sum"":"      TXSM-SO-AMOUNT-SUM ","
                   """ctrl_match"":"""    TXSM-SO-CTRL-TOTAL-MATCH """"
                   "}"
           IF TXSM-SO-STATUS = "16"
               MOVE 16 TO WS-RC
           END-IF.

       DO-STAGE4.
           ACCEPT WS-ARG FROM ARGUMENT-VALUE
           MOVE WS-ARG(1:14) TO TXSM-MI-BATCH-ID
           ACCEPT WS-ARG FROM ARGUMENT-VALUE
           COMPUTE TXSM-MI-BUSINESS-DATE =
               FUNCTION NUMVAL(WS-ARG)
           ACCEPT TXSM-MI-SORTED-FILENAME FROM ARGUMENT-VALUE
           ACCEPT TXSM-MI-RECON-PREV-FILENAME FROM ARGUMENT-VALUE
           ACCEPT TXSM-MI-READY-FILENAME FROM ARGUMENT-VALUE
           ACCEPT TXSM-MI-ERROR-FILENAME FROM ARGUMENT-VALUE
           ACCEPT TXSM-MI-CHECKPOINT-FILENAME FROM ARGUMENT-VALUE
           ACCEPT TXSM-MI-TEMP-FILENAME FROM ARGUMENT-VALUE
           CALL "TXSM-MERGE-BATCH" USING
                TXSM-MERGE-INPUT TXSM-MERGE-OUTPUT
           DISPLAY "{"
                   """status"":"""        TXSM-MO-STATUS ""","
                   """sorted_in"":"       TXSM-MO-RECORDS-SORTED-IN ","
                   """recon_in"":"        TXSM-MO-RECORDS-RECON-IN ","
                   """merged_out"":"      TXSM-MO-RECORDS-MERGED-OUT ","
                   """dup_records"":"     TXSM-MO-DUPLICATE-RECORDS ","
                   """dup_pairs"":"       TXSM-MO-DUPLICATE-PAIRS ","
                   """recon_present"":""" TXSM-MO-RECON-PRESENT-FLAG ""","
                   """amount_sum"":"      TXSM-MO-AMOUNT-SUM
                   "}"
           IF TXSM-MO-STATUS = "16"
               MOVE 16 TO WS-RC
           END-IF.

       DO-STAGE5.
           ACCEPT WS-ARG FROM ARGUMENT-VALUE
           MOVE WS-ARG(1:14) TO TXPR-IN-BATCH-ID
           ACCEPT WS-ARG FROM ARGUMENT-VALUE
           COMPUTE TXPR-IN-BUSINESS-DATE =
               FUNCTION NUMVAL(WS-ARG)
           ACCEPT TXPR-IN-READY-FILENAME FROM ARGUMENT-VALUE
           ACCEPT TXPR-IN-ERROR-FILENAME FROM ARGUMENT-VALUE
           ACCEPT TXPR-IN-RECON-DEFER-FILENAME FROM ARGUMENT-VALUE
           ACCEPT TXPR-IN-CHECKPOINT-FILENAME FROM ARGUMENT-VALUE
           ACCEPT TXPR-IN-DORMANCY-FILENAME FROM ARGUMENT-VALUE
           CALL "TXPOST-RUN-BATCH" USING
                TXPOST-RUN-INPUT TXPOST-RUN-OUTPUT
           DISPLAY "{"
                   """status"":"""             TXPR-STATUS ""","
                   """records_read"":"         TXPR-RECORDS-READ ","
                   """records_attempted"":"    TXPR-RECORDS-ATTEMPTED ","
                   """records_posted"":"       TXPR-RECORDS-POSTED ","
                   """already_skipped"":"      TXPR-ALREADY-POSTED-SKIPPED ","
                   """hard_rejected"":"        TXPR-HARD-REJECTED ","
                   """in_doubt_resolved"":"    TXPR-IN-DOUBT-RESOLVED ","
                   """recon_defer"":"          TXPR-RECON-DEFERRED ","
                   """dorm_defer"":"           TXPR-DORMANCY-DEFERRED
                   "}"
           IF TXPR-STATUS = "16"
               MOVE 16 TO WS-RC
           END-IF.

       DO-REVERSE.
           ACCEPT WS-ARG FROM ARGUMENT-VALUE
           MOVE WS-ARG(1:18) TO TXPV-ORIG-TXN-ID
           ACCEPT WS-ARG FROM ARGUMENT-VALUE
           MOVE WS-ARG(1:80) TO TXPV-REVERSAL-REASON
           ACCEPT WS-ARG FROM ARGUMENT-VALUE
           MOVE WS-ARG(1:20) TO TXPV-OPERATOR-ID
           CALL "TXPOST-REVERSE" USING
                TXPOST-REVERSE-INPUT TXPOST-REVERSE-OUTPUT
           DISPLAY "{"
                   """status"":"""          TXPV-STATUS ""","
                   """new_rv_txn_id"":"""    TXPV-NEW-RV-TXN-ID ""","
                   """in_doubt_resolved"":"""
                                            TXPV-IN-DOUBT-RESOLVED """"
                   "}"
           IF TXPV-STATUS = "16"
               MOVE 16 TO WS-RC
           END-IF.

       END PROGRAM E2E-DRIVER.
