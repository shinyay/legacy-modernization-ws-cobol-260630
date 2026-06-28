       IDENTIFICATION DIVISION.
       PROGRAM-ID. TXSM-MERGE-BATCH.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TXN-SORTED-FILE
               ASSIGN TO WS-SORTED-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-SORTED.
           SELECT TXN-RECON-PREV-FILE
               ASSIGN TO WS-RECON-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-RECON.
           SELECT TXN-READY-FILE
               ASSIGN TO WS-READY-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-READY.
           SELECT TXN-ERROR-FILE
               ASSIGN TO WS-ERROR-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-ERROR.
           SELECT TXN-READY-D-TEMP-FILE
               ASSIGN TO WS-TEMP-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-TEMP.

       DATA DIVISION.
       FILE SECTION.
           COPY "fd-txn-sorted.cpy".
           COPY "fd-txn-recon-prev.cpy".
           COPY "fd-txn-ready.cpy".
           COPY "fd-txn-error.cpy".
           COPY "fd-txn-ready-d-temp.cpy".

       WORKING-STORAGE SECTION.
       01  WS-SORTED-PATH              PIC X(80) VALUE SPACES.
       01  WS-RECON-PATH               PIC X(80) VALUE SPACES.
       01  WS-READY-PATH               PIC X(80) VALUE SPACES.
       01  WS-ERROR-PATH               PIC X(80) VALUE SPACES.
       01  WS-TEMP-PATH                PIC X(80) VALUE SPACES.

       01  WS-FS-SORTED                PIC X(2).
       01  WS-FS-RECON                 PIC X(2).
       01  WS-FS-READY                 PIC X(2).
       01  WS-FS-ERROR                 PIC X(2).
       01  WS-FS-TEMP                  PIC X(2).

           COPY "ws-txn-decoded-record.cpy".

           COPY "ws-merge-state.cpy".

           COPY "ws-control-totals.cpy".

       01  WS-SAVED-HEADER             PIC X(600) VALUE SPACES.
       01  WS-SAVED-TRAILER            PIC X(600) VALUE SPACES.

       01  WS-COMPARE-WORK.
           05  WS-KEY-SORTED.
               10  WS-KS-PAYER          PIC X(13).
               10  WS-KS-SEQ            PIC 9(10).
           05  WS-KEY-RECON.
               10  WS-KR-PAYER          PIC X(13).
               10  WS-KR-SEQ            PIC 9(10).

       01  WS-SCRATCH.
           05  WS-SCRATCH-REC           PIC X(600).
       01  WS-SCRATCH-D REDEFINES WS-SCRATCH.
           05  WS-SCRD-TYPE             PIC X(1).
           05  WS-SCRD-SEQ              PIC 9(10).
           05  WS-SCRD-CAT              PIC X(2).
           05  WS-SCRD-AMOUNT           PIC 9(15).
           05  WS-SCRD-CCY              PIC X(3).
           05  WS-SCRD-PAYER            PIC X(13).
           05  WS-SCRD-FILLER           PIC X(556).

       01  WS-OUT-HEADER.
           05  OH-TYPE                  PIC X(1) VALUE "H".
           05  OH-BATCH                 PIC X(14).
           05  OH-BDATE                 PIC 9(8).
           05  OH-SRC                   PIC X(20) VALUE "11-MERGE".
           05  OH-EXPECTED              PIC 9(10).
           05  OH-CHKSUM                PIC X(40) VALUE
                                            "0000000000000000000000000000000000000000".
           05  OH-FILLER                PIC X(507) VALUE SPACES.

       01  WS-OUT-TRAILER.
           05  OT-TYPE                  PIC X(1) VALUE "T".
           05  OT-COUNT                 PIC 9(10).
           05  OT-AMTSUM                PIC 9(20).
           05  OT-CHKSUM                PIC X(40) VALUE
                                            "0000000000000000000000000000000000000000".
           05  OT-FILLER                PIC X(529) VALUE SPACES.

           COPY "shared-log-api.cpy".

       01  WS-CMD                      PIC X(200).

       LINKAGE SECTION.
           COPY "tx-sm-api.cpy".

       PROCEDURE DIVISION USING TXSM-MERGE-INPUT
                                TXSM-MERGE-OUTPUT.
       MAIN-LOGIC SECTION.
       M-START.
           PERFORM INIT-OUTPUT-AREA
           PERFORM COPY-PATHS-FROM-LINKAGE
           PERFORM PREP-TEMP-DIR
           PERFORM CHECK-RECON-EXISTS
           IF WS-RECON-PRESENT
               PERFORM VERIFY-RECON-SORT-ORDER
               IF NOT TXSM-MO-OK AND NOT TXSM-MO-PARTIAL
                   PERFORM PUBLISH-COUNTERS
                   PERFORM EMIT-AUDIT-SUMMARY
                   GOBACK
               END-IF
           END-IF
           PERFORM OPEN-MERGE-FILES
           IF NOT TXSM-MO-OK AND NOT TXSM-MO-PARTIAL
               PERFORM PUBLISH-COUNTERS
               PERFORM EMIT-AUDIT-SUMMARY
               GOBACK
           END-IF
           IF WS-RECON-PRESENT
               PERFORM MERGE-2WAY-WITH-RECON
           ELSE
               PERFORM MERGE-PASSTHROUGH-SORTED-ONLY
           END-IF
           PERFORM CLOSE-D-STREAM-FILES
           PERFORM WRITE-FINAL-READY
           PERFORM CLEANUP-TEMP
           PERFORM PUBLISH-COUNTERS
           PERFORM SET-FINAL-STATUS
           PERFORM EMIT-AUDIT-SUMMARY
           GOBACK.

       INIT-OUTPUT-AREA.
           SET TXSM-MO-OK TO TRUE
           MOVE 0    TO TXSM-MO-RECORDS-SORTED-IN
                        TXSM-MO-RECORDS-RECON-IN
                        TXSM-MO-RECORDS-MERGED-OUT
                        TXSM-MO-DUPLICATE-RECORDS
                        TXSM-MO-DUPLICATE-PAIRS
                        TXSM-MO-SORT-VIOLATIONS
                        TXSM-MO-AMOUNT-SUM
           MOVE "N"  TO TXSM-MO-RECON-PRESENT-FLAG
           MOVE 0    TO WS-MERGE-SORTED-IN WS-MERGE-RECON-IN
                        WS-MERGE-D-COUNT
                        WS-MERGE-AMOUNT-SUM
                        WS-DUPLICATE-RECORD-COUNT
                        WS-DUPLICATE-PAIR-COUNT
                        WS-SORT-VIOLATION-COUNT
           MOVE 0    TO WS-RECON-EXISTS
           MOVE "N"  TO WS-SORTED-EOF WS-RECON-EOF
                        WS-TEMP-COPY-EOF
                        WS-MERGE-CTRL-MATCH
           MOVE "Y"  TO WS-RSP-FIRST
           MOVE SPACES TO WS-SAVED-HEADER WS-SAVED-TRAILER.

       COPY-PATHS-FROM-LINKAGE.
           MOVE FUNCTION TRIM(TXSM-MI-SORTED-FILENAME)
               TO WS-SORTED-PATH
           MOVE FUNCTION TRIM(TXSM-MI-RECON-PREV-FILENAME)
               TO WS-RECON-PATH
           MOVE FUNCTION TRIM(TXSM-MI-READY-FILENAME)
               TO WS-READY-PATH
           MOVE FUNCTION TRIM(TXSM-MI-ERROR-FILENAME)
               TO WS-ERROR-PATH
           MOVE FUNCTION TRIM(TXSM-MI-TEMP-FILENAME)
               TO WS-TEMP-PATH.

       PREP-TEMP-DIR.
           CONTINUE.

       CHECK-RECON-EXISTS.
           MOVE 0 TO WS-RECON-EXISTS
           MOVE "N" TO TXSM-MO-RECON-PRESENT-FLAG
           OPEN INPUT TXN-RECON-PREV-FILE
           IF WS-FS-RECON = "00"
               MOVE 1 TO WS-RECON-EXISTS
               MOVE "Y" TO TXSM-MO-RECON-PRESENT-FLAG
               CLOSE TXN-RECON-PREV-FILE
           ELSE
               IF WS-FS-RECON = "35"
                   CONTINUE
               ELSE
                   MOVE "11-txsm-merge" TO WS-LOG-SUBSYSTEM
                   MOVE "WARN " TO WS-LOG-LEVEL
                   STRING "RECON-OPEN-UNEXPECTED fs=" WS-FS-RECON
                          DELIMITED BY SIZE INTO WS-LOG-MESSAGE
                   PERFORM EMIT-LOG
               END-IF
           END-IF.

       VERIFY-RECON-SORT-ORDER.
           OPEN INPUT TXN-RECON-PREV-FILE
           IF WS-FS-RECON NOT = "00"
               SET TXSM-MO-IO-FAIL TO TRUE
               EXIT PARAGRAPH
           END-IF
           PERFORM UNTIL WS-RECON-IS-EOF
               READ TXN-RECON-PREV-FILE INTO TXN-DECODED-REC
                   AT END
                       SET WS-RECON-IS-EOF TO TRUE
                   NOT AT END
                       PERFORM SCAN-CHECK-RECON-D
               END-READ
           END-PERFORM
           CLOSE TXN-RECON-PREV-FILE
           MOVE "N" TO WS-RECON-EOF.

       SCAN-CHECK-RECON-D.
           IF NOT TXN-IS-DETAIL
               EXIT PARAGRAPH
           END-IF
           IF WS-RSP-IS-FIRST
               MOVE TDD-PAYER-ACCT TO WS-RSP-PAYER-ACCT
               MOVE TDD-SEQ        TO WS-RSP-SEQ
               MOVE "N" TO WS-RSP-FIRST
               EXIT PARAGRAPH
           END-IF
           IF TDD-PAYER-ACCT < WS-RSP-PAYER-ACCT
               ADD 1 TO WS-SORT-VIOLATION-COUNT
               MOVE "11-txsm-merge" TO WS-LOG-SUBSYSTEM
               MOVE "ERROR" TO WS-LOG-LEVEL
               STRING "RECON-SORT-VIOLATION prev="
                      WS-RSP-PAYER-ACCT
                      " cur=" TDD-PAYER-ACCT
                      DELIMITED BY SIZE INTO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
               SET TXSM-MO-INVALID TO TRUE
           ELSE
               IF TDD-PAYER-ACCT = WS-RSP-PAYER-ACCT AND
                  TDD-SEQ < WS-RSP-SEQ
                   ADD 1 TO WS-SORT-VIOLATION-COUNT
                   SET TXSM-MO-INVALID TO TRUE
               END-IF
           END-IF
           MOVE TDD-PAYER-ACCT TO WS-RSP-PAYER-ACCT
           MOVE TDD-SEQ        TO WS-RSP-SEQ.

       OPEN-MERGE-FILES.
           OPEN INPUT TXN-SORTED-FILE
           IF WS-FS-SORTED NOT = "00"
               STRING "SORTED-OPEN-FAIL fs=" WS-FS-SORTED
                      DELIMITED BY SIZE INTO WS-LOG-MESSAGE
               MOVE "11-txsm-merge" TO WS-LOG-SUBSYSTEM
               MOVE "ERROR" TO WS-LOG-LEVEL
               PERFORM EMIT-LOG
               SET TXSM-MO-IO-FAIL TO TRUE
               EXIT PARAGRAPH
           END-IF
           IF WS-RECON-PRESENT
               OPEN INPUT TXN-RECON-PREV-FILE
               IF WS-FS-RECON NOT = "00"
                   SET TXSM-MO-IO-FAIL TO TRUE
                   EXIT PARAGRAPH
               END-IF
           END-IF
           OPEN OUTPUT TXN-READY-D-TEMP-FILE
           IF WS-FS-TEMP NOT = "00"
               STRING "TEMP-OPEN-FAIL fs=" WS-FS-TEMP
                      " path=" FUNCTION TRIM(WS-TEMP-PATH)
                      DELIMITED BY SIZE INTO WS-LOG-MESSAGE
               MOVE "11-txsm-merge" TO WS-LOG-SUBSYSTEM
               MOVE "ERROR" TO WS-LOG-LEVEL
               PERFORM EMIT-LOG
               SET TXSM-MO-IO-FAIL TO TRUE
               EXIT PARAGRAPH
           END-IF
           OPEN EXTEND TXN-ERROR-FILE
           IF WS-FS-ERROR = "35"
               OPEN OUTPUT TXN-ERROR-FILE
           END-IF
           IF WS-FS-ERROR NOT = "00"
               SET TXSM-MO-IO-FAIL TO TRUE
           END-IF.

       MERGE-PASSTHROUGH-SORTED-ONLY.
           MOVE "N" TO WS-SORTED-EOF
           PERFORM UNTIL WS-SORTED-IS-EOF
               READ TXN-SORTED-FILE INTO TXN-DECODED-REC
                   AT END
                       SET WS-SORTED-IS-EOF TO TRUE
                   NOT AT END
                       EVALUATE TRUE
                           WHEN TXN-IS-HEADER
                               MOVE TXN-DECODED-REC
                                    TO WS-SAVED-HEADER
                           WHEN TXN-IS-DETAIL
                               PERFORM WRITE-TEMP-D-FROM-DECODED
                               ADD 1 TO WS-MERGE-SORTED-IN
                           WHEN TXN-IS-TRAILER
                               MOVE TXN-DECODED-REC
                                    TO WS-SAVED-TRAILER
                       END-EVALUATE
               END-READ
           END-PERFORM.

       WRITE-TEMP-D-FROM-DECODED.
           WRITE TXN-READY-D-TEMP-REC FROM TXN-DECODED-REC
           ADD 1 TO WS-MERGE-D-COUNT
           ADD TDD-AMOUNT-JPY TO WS-MERGE-AMOUNT-SUM.

       MERGE-2WAY-WITH-RECON.
           MOVE "N" TO WS-SORTED-EOF WS-RECON-EOF
           PERFORM READ-NEXT-D-FROM-SORTED
           PERFORM READ-NEXT-D-FROM-RECON
           PERFORM UNTIL WS-SORTED-IS-EOF AND WS-RECON-IS-EOF
               EVALUATE TRUE
                   WHEN WS-SORTED-IS-EOF
                       PERFORM EMIT-RECON-AND-ADVANCE
                   WHEN WS-RECON-IS-EOF
                       PERFORM EMIT-SORTED-AND-ADVANCE
                   WHEN WS-KEY-SORTED < WS-KEY-RECON
                       PERFORM EMIT-SORTED-AND-ADVANCE
                   WHEN WS-KEY-SORTED > WS-KEY-RECON
                       PERFORM EMIT-RECON-AND-ADVANCE
                   WHEN OTHER
                       PERFORM HANDLE-DUPLICATE-AT-MERGE
                       PERFORM READ-NEXT-D-FROM-SORTED
                       PERFORM READ-NEXT-D-FROM-RECON
               END-EVALUATE
           END-PERFORM.

       READ-NEXT-D-FROM-SORTED.
           IF WS-SORTED-IS-EOF
               EXIT PARAGRAPH
           END-IF
           PERFORM UNTIL WS-SORTED-IS-EOF
               READ TXN-SORTED-FILE INTO TXN-DECODED-REC
                   AT END
                       SET WS-SORTED-IS-EOF TO TRUE
                       EXIT PERFORM
                   NOT AT END
                       EVALUATE TRUE
                           WHEN TXN-IS-HEADER
                               MOVE TXN-DECODED-REC
                                    TO WS-SAVED-HEADER
                           WHEN TXN-IS-TRAILER
                               MOVE TXN-DECODED-REC
                                    TO WS-SAVED-TRAILER
                           WHEN TXN-IS-DETAIL
                               MOVE TXN-DECODED-REC TO WS-SORTED-CUR-REC
                               MOVE TDD-PAYER-ACCT  TO WS-SORTED-K-PAYER
                               MOVE TDD-SEQ         TO WS-SORTED-K-SEQ
                               MOVE WS-SORTED-K-PAYER TO WS-KS-PAYER
                               MOVE WS-SORTED-K-SEQ   TO WS-KS-SEQ
                               ADD 1 TO WS-MERGE-SORTED-IN
                               EXIT PERFORM
                       END-EVALUATE
               END-READ
           END-PERFORM.

       READ-NEXT-D-FROM-RECON.
           IF WS-RECON-IS-EOF
               EXIT PARAGRAPH
           END-IF
           PERFORM UNTIL WS-RECON-IS-EOF
               READ TXN-RECON-PREV-FILE INTO TXN-DECODED-REC
                   AT END
                       SET WS-RECON-IS-EOF TO TRUE
                       EXIT PERFORM
                   NOT AT END
                       IF TXN-IS-DETAIL
                           MOVE TXN-DECODED-REC TO WS-RECON-CUR-REC
                           MOVE TDD-PAYER-ACCT  TO WS-RECON-K-PAYER
                           MOVE TDD-SEQ         TO WS-RECON-K-SEQ
                           MOVE WS-RECON-K-PAYER TO WS-KR-PAYER
                           MOVE WS-RECON-K-SEQ   TO WS-KR-SEQ
                           ADD 1 TO WS-MERGE-RECON-IN
                           EXIT PERFORM
                       END-IF
               END-READ
           END-PERFORM.

       EMIT-SORTED-AND-ADVANCE.
           MOVE WS-SORTED-CUR-REC TO WS-SCRATCH-REC
           WRITE TXN-READY-D-TEMP-REC FROM WS-SCRATCH-REC
           ADD 1 TO WS-MERGE-D-COUNT
           ADD WS-SCRD-AMOUNT TO WS-MERGE-AMOUNT-SUM
           PERFORM READ-NEXT-D-FROM-SORTED.

       EMIT-RECON-AND-ADVANCE.
           MOVE WS-RECON-CUR-REC TO WS-SCRATCH-REC
           WRITE TXN-READY-D-TEMP-REC FROM WS-SCRATCH-REC
           ADD 1 TO WS-MERGE-D-COUNT
           ADD WS-SCRD-AMOUNT TO WS-MERGE-AMOUNT-SUM
           PERFORM READ-NEXT-D-FROM-RECON.

       HANDLE-DUPLICATE-AT-MERGE.
           MOVE WS-SORTED-K-SEQ TO TEF-ORIG-SEQ
           MOVE "E050"          TO TEF-REASON-CODE
           STRING "dup at merge: " WS-SORTED-K-PAYER
                  " seq=" WS-SORTED-K-SEQ
                  DELIMITED BY SIZE INTO TEF-REASON-TEXT
           MOVE WS-SORTED-CUR-REC TO TEF-ORIG-REC
           WRITE TXN-ERROR-FD-REC
           MOVE WS-RECON-K-SEQ TO TEF-ORIG-SEQ
           MOVE "E050"          TO TEF-REASON-CODE
           STRING "dup at merge: " WS-RECON-K-PAYER
                  " seq=" WS-RECON-K-SEQ
                  DELIMITED BY SIZE INTO TEF-REASON-TEXT
           MOVE WS-RECON-CUR-REC TO TEF-ORIG-REC
           WRITE TXN-ERROR-FD-REC
           ADD 2 TO WS-DUPLICATE-RECORD-COUNT
           ADD 1 TO WS-DUPLICATE-PAIR-COUNT.

       CLOSE-D-STREAM-FILES.
           CLOSE TXN-READY-D-TEMP-FILE
           CLOSE TXN-SORTED-FILE
           IF WS-RECON-PRESENT
               CLOSE TXN-RECON-PREV-FILE
           END-IF
           CLOSE TXN-ERROR-FILE.

       WRITE-FINAL-READY.
           OPEN OUTPUT TXN-READY-FILE
           IF WS-FS-READY NOT = "00"
               SET TXSM-MO-IO-FAIL TO TRUE
               EXIT PARAGRAPH
           END-IF
           MOVE TXSM-MI-BATCH-ID      TO OH-BATCH
           MOVE TXSM-MI-BUSINESS-DATE TO OH-BDATE
           MOVE WS-MERGE-D-COUNT      TO OH-EXPECTED
           WRITE TXN-READY-REC FROM WS-OUT-HEADER

           OPEN INPUT TXN-READY-D-TEMP-FILE
           IF WS-FS-TEMP NOT = "00"
               SET TXSM-MO-IO-FAIL TO TRUE
               EXIT PARAGRAPH
           END-IF
           MOVE "N" TO WS-TEMP-COPY-EOF
           PERFORM COPY-TEMP-TO-READY UNTIL WS-TEMP-COPY-IS-EOF

           CLOSE TXN-READY-D-TEMP-FILE

           MOVE WS-MERGE-D-COUNT     TO OT-COUNT
           MOVE WS-MERGE-AMOUNT-SUM  TO OT-AMTSUM
           WRITE TXN-READY-REC FROM WS-OUT-TRAILER
           CLOSE TXN-READY-FILE.

       COPY-TEMP-TO-READY.
           READ TXN-READY-D-TEMP-FILE INTO WS-SCRATCH-REC
               AT END
                   SET WS-TEMP-COPY-IS-EOF TO TRUE
                   EXIT PARAGRAPH
               NOT AT END
                   WRITE TXN-READY-REC FROM WS-SCRATCH-REC
           END-READ.

       CLEANUP-TEMP.
           MOVE SPACES TO WS-CMD
           STRING "rm -f "
                  FUNCTION TRIM(WS-TEMP-PATH)
                  DELIMITED BY SIZE INTO WS-CMD
           CALL "SYSTEM" USING WS-CMD.

       PUBLISH-COUNTERS.
           MOVE WS-MERGE-SORTED-IN  TO TXSM-MO-RECORDS-SORTED-IN
           MOVE WS-MERGE-RECON-IN   TO TXSM-MO-RECORDS-RECON-IN
           MOVE WS-MERGE-D-COUNT    TO TXSM-MO-RECORDS-MERGED-OUT
           MOVE WS-MERGE-AMOUNT-SUM TO TXSM-MO-AMOUNT-SUM
           MOVE WS-DUPLICATE-RECORD-COUNT
                                    TO TXSM-MO-DUPLICATE-RECORDS
           MOVE WS-DUPLICATE-PAIR-COUNT
                                    TO TXSM-MO-DUPLICATE-PAIRS
           MOVE WS-SORT-VIOLATION-COUNT
                                    TO TXSM-MO-SORT-VIOLATIONS.

       SET-FINAL-STATUS.
           EVALUATE TRUE
               WHEN TXSM-MO-INVALID  CONTINUE
               WHEN TXSM-MO-IO-FAIL  CONTINUE
               WHEN TXSM-MO-FATAL    CONTINUE
               WHEN WS-DUPLICATE-RECORD-COUNT > 0
                   SET TXSM-MO-PARTIAL TO TRUE
               WHEN OTHER
                   SET TXSM-MO-OK TO TRUE
           END-EVALUATE
           IF (WS-MERGE-SORTED-IN + WS-MERGE-RECON-IN) =
              (WS-MERGE-D-COUNT + WS-DUPLICATE-RECORD-COUNT)
               MOVE "Y" TO WS-MERGE-CTRL-MATCH
           ELSE
               MOVE "11-txsm-merge" TO WS-LOG-SUBSYSTEM
               MOVE "ERROR" TO WS-LOG-LEVEL
               STRING "CONSERVATION-VIOLATION sin="
                      WS-MERGE-SORTED-IN " rin=" WS-MERGE-RECON-IN
                      " out=" WS-MERGE-D-COUNT
                      " dup=" WS-DUPLICATE-RECORD-COUNT
                      DELIMITED BY SIZE INTO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
               SET TXSM-MO-INVALID TO TRUE
           END-IF.

       EMIT-AUDIT-SUMMARY.
           MOVE "11-txsm-merge" TO WS-LOG-SUBSYSTEM
           MOVE "INFO " TO WS-LOG-LEVEL
           STRING "MERGE-BATCH batch="
                  FUNCTION TRIM(TXSM-MI-BATCH-ID)
                  ",sin=" WS-MERGE-SORTED-IN
                  ",rin=" WS-MERGE-RECON-IN
                  ",out=" WS-MERGE-D-COUNT
                  ",dup=" WS-DUPLICATE-RECORD-COUNT
                  ",viol=" WS-SORT-VIOLATION-COUNT
                  ",status=" TXSM-MO-STATUS
                  DELIMITED BY SIZE INTO WS-LOG-MESSAGE
           PERFORM EMIT-LOG.

       EMIT-LOG.
           CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC
           ON EXCEPTION CONTINUE
           END-CALL.

       END PROGRAM TXSM-MERGE-BATCH.
