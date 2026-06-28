       IDENTIFICATION DIVISION.
       PROGRAM-ID. TXSM-SORT-BATCH.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TXN-VALID-FILE
               ASSIGN TO WS-IN-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-IN.
           SELECT TXN-SORTED-FILE
               ASSIGN TO WS-SORTED-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-SORTED.
           SELECT SORT-WORK-FILE
               ASSIGN TO "SORTWK".

       DATA DIVISION.
       FILE SECTION.
           COPY "fd-txn-valid-in.cpy".
           COPY "fd-txn-sorted.cpy".
           COPY "sd-txn-sort.cpy".

       WORKING-STORAGE SECTION.
       01  WS-IN-PATH                  PIC X(80) VALUE SPACES.
       01  WS-SORTED-PATH              PIC X(80) VALUE SPACES.

       01  WS-FS-IN                    PIC X(2).
       01  WS-FS-SORTED                PIC X(2).

       01  WS-SAVED-HEADER             PIC X(600) VALUE SPACES.
       01  WS-SAVED-TRAILER            PIC X(600) VALUE SPACES.
       01  WS-HEADER-SEEN              PIC X(1) VALUE "N".
           88  WS-HEADER-OK                     VALUE "Y".
       01  WS-TRAILER-SEEN             PIC X(1) VALUE "N".
           88  WS-TRAILER-OK                    VALUE "Y".

       01  WS-EOF-INPUT                PIC X(1) VALUE "N".
           88  WS-EOF-INPUT-Y                   VALUE "Y".
       01  WS-EOF-RETURN               PIC X(1) VALUE "N".
           88  WS-EOF-RETURN-Y                  VALUE "Y".
       01  WS-UNKNOWN-TYPE-COUNT       PIC 9(5) VALUE 0.

           COPY "ws-txn-decoded-record.cpy".

           COPY "ws-control-totals.cpy".

       01  WS-PAYLOAD                  PIC X(600).
       01  WS-PAYLOAD-D REDEFINES WS-PAYLOAD.
           05  WSP-REC-TYPE             PIC X(1).
           05  WSP-SEQ                  PIC 9(10).
           05  WSP-CATEGORY             PIC X(2).
           05  WSP-AMOUNT               PIC 9(15).
           05  WSP-FILLER               PIC X(572).

       01  WS-TRAILER-OVERLAY.
           05  WS-TR-REC                PIC X(600).
       01  WS-TRAILER-OVERLAY-T REDEFINES WS-TRAILER-OVERLAY.
           05  WS-TT-REC-TYPE           PIC X(1).
           05  WS-TT-RECORD-COUNT       PIC 9(10).
           05  WS-TT-AMOUNT-SUM         PIC 9(20).
           05  WS-TT-CHECKSUM           PIC X(40).
           05  WS-TT-FILLER             PIC X(529).

           COPY "shared-log-api.cpy".

       LINKAGE SECTION.
           COPY "tx-sm-api.cpy".

       PROCEDURE DIVISION USING TXSM-SORT-INPUT
                                TXSM-SORT-OUTPUT.
       MAIN-LOGIC SECTION.
       M-START.
           PERFORM INIT-OUTPUT-AREA
           PERFORM COPY-PATHS-FROM-LINKAGE
           PERFORM EXECUTE-SORT
           PERFORM VERIFY-LOSSLESS-INVARIANT
           PERFORM PUBLISH-COUNTERS
           PERFORM EMIT-AUDIT-SUMMARY
           GOBACK.

       INIT-OUTPUT-AREA.
           SET TXSM-SO-OK TO TRUE
           MOVE 0     TO TXSM-SO-RECORDS-PROCESSED
                         TXSM-SO-RECORDS-SORTED
                         TXSM-SO-AMOUNT-SUM
           MOVE "N"   TO TXSM-SO-CTRL-TOTAL-MATCH
           MOVE 0     TO WS-SORT-RECORDS-IN
                         WS-SORT-RECORDS-OUT
                         WS-SORT-AMOUNT-SUM
                         WS-SORT-HEADER-COUNT
                         WS-SORT-TRAILER-COUNT
                         WS-SORT-TRAILER-SUM
           MOVE 0     TO WS-UNKNOWN-TYPE-COUNT
           MOVE "N"   TO WS-EOF-INPUT WS-EOF-RETURN
                         WS-HEADER-SEEN WS-TRAILER-SEEN
                         WS-SORT-CTRL-MATCH
           MOVE SPACES TO WS-SAVED-HEADER WS-SAVED-TRAILER.

       COPY-PATHS-FROM-LINKAGE.
           MOVE FUNCTION TRIM(TXSM-SI-INPUT-FILENAME)
               TO WS-IN-PATH
           MOVE FUNCTION TRIM(TXSM-SI-OUTPUT-FILENAME)
               TO WS-SORTED-PATH.

       EXECUTE-SORT.
           SORT SORT-WORK-FILE
               ON ASCENDING KEY SR-PAYER-ACCT SR-SEQ
               INPUT  PROCEDURE IS SORT-INPUT-PARA
               OUTPUT PROCEDURE IS SORT-OUTPUT-PARA.

       SORT-INPUT-PARA.
           OPEN INPUT TXN-VALID-FILE
           IF WS-FS-IN NOT = "00"
               MOVE "10-txnvalidate-sort" TO WS-LOG-SUBSYSTEM
               MOVE "ERROR" TO WS-LOG-LEVEL
               STRING "SORT-INPUT-OPEN-FAIL fs="
                      WS-FS-IN " path="
                      FUNCTION TRIM(WS-IN-PATH)
                      DELIMITED BY SIZE INTO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
               SET TXSM-SO-IO-FAIL TO TRUE
               EXIT PARAGRAPH
           END-IF
           PERFORM UNTIL WS-EOF-INPUT-Y
               READ TXN-VALID-FILE INTO TXN-DECODED-REC
                   AT END
                       SET WS-EOF-INPUT-Y TO TRUE
                   NOT AT END
                       PERFORM DISPATCH-INPUT-RECORD
               END-READ
           END-PERFORM
           CLOSE TXN-VALID-FILE.

       DISPATCH-INPUT-RECORD.
           EVALUATE TRUE
               WHEN TXN-IS-HEADER
                   MOVE TXN-DECODED-REC TO WS-SAVED-HEADER
                   SET WS-HEADER-OK TO TRUE
                   MOVE TDH-EXPECTED-COUNT TO WS-SORT-HEADER-COUNT
               WHEN TXN-IS-DETAIL
                   MOVE TDD-PAYER-ACCT       TO SR-PAYER-ACCT
                   MOVE TDD-SEQ              TO SR-SEQ
                   MOVE TXN-DECODED-REC      TO SR-FULL-RECORD
                   RELEASE SORT-WORK-REC
                   ADD 1 TO WS-SORT-RECORDS-IN
               WHEN TXN-IS-TRAILER
                   MOVE TXN-DECODED-REC TO WS-SAVED-TRAILER
                   SET WS-TRAILER-OK TO TRUE
                   MOVE WS-SAVED-TRAILER TO WS-TRAILER-OVERLAY
                   MOVE WS-TT-RECORD-COUNT TO WS-SORT-TRAILER-COUNT
                   MOVE WS-TT-AMOUNT-SUM   TO WS-SORT-TRAILER-SUM
               WHEN OTHER
                   ADD 1 TO WS-UNKNOWN-TYPE-COUNT
           END-EVALUATE.

       SORT-OUTPUT-PARA.
           OPEN OUTPUT TXN-SORTED-FILE
           IF WS-FS-SORTED NOT = "00"
               MOVE "10-txnvalidate-sort" TO WS-LOG-SUBSYSTEM
               MOVE "ERROR" TO WS-LOG-LEVEL
               STRING "SORT-OUTPUT-OPEN-FAIL fs="
                      WS-FS-SORTED
                      DELIMITED BY SIZE INTO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
               SET TXSM-SO-IO-FAIL TO TRUE
               EXIT PARAGRAPH
           END-IF

           IF WS-HEADER-OK
               WRITE TXN-SORTED-REC FROM WS-SAVED-HEADER
           END-IF

           PERFORM UNTIL WS-EOF-RETURN-Y
               RETURN SORT-WORK-FILE
                   AT END
                       SET WS-EOF-RETURN-Y TO TRUE
                   NOT AT END
                       PERFORM EMIT-SORTED-D
               END-RETURN
           END-PERFORM

           IF WS-TRAILER-OK
               MOVE WS-SAVED-TRAILER TO WS-TRAILER-OVERLAY
               MOVE WS-SORT-RECORDS-OUT TO WS-TT-RECORD-COUNT
               MOVE WS-SORT-AMOUNT-SUM  TO WS-TT-AMOUNT-SUM
               WRITE TXN-SORTED-REC FROM WS-TRAILER-OVERLAY
           END-IF

           CLOSE TXN-SORTED-FILE.

       EMIT-SORTED-D.
           MOVE SR-FULL-RECORD TO TXN-SORTED-REC
           MOVE SR-FULL-RECORD TO WS-PAYLOAD
           WRITE TXN-SORTED-REC
           ADD 1 TO WS-SORT-RECORDS-OUT
           ADD WSP-AMOUNT TO WS-SORT-AMOUNT-SUM.

       VERIFY-LOSSLESS-INVARIANT.
           IF NOT TXSM-SO-OK AND NOT TXSM-SO-PARTIAL
               EXIT PARAGRAPH
           END-IF
           IF WS-SORT-RECORDS-IN NOT = WS-SORT-RECORDS-OUT
               MOVE "10-txnvalidate-sort" TO WS-LOG-SUBSYSTEM
               MOVE "ERROR" TO WS-LOG-LEVEL
               STRING "LOSSLESS-VIOLATION in=" WS-SORT-RECORDS-IN
                      " out=" WS-SORT-RECORDS-OUT
                      DELIMITED BY SIZE INTO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
               SET TXSM-SO-INVALID TO TRUE
               EXIT PARAGRAPH
           END-IF
           IF WS-HEADER-OK AND
              WS-SORT-HEADER-COUNT NOT = WS-SORT-RECORDS-OUT
               MOVE "10-txnvalidate-sort" TO WS-LOG-SUBSYSTEM
               MOVE "WARN " TO WS-LOG-LEVEL
               STRING "CTRL-HEADER-MISMATCH expected="
                      WS-SORT-HEADER-COUNT " actual="
                      WS-SORT-RECORDS-OUT
                      DELIMITED BY SIZE INTO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
               SET TXSM-SO-PARTIAL TO TRUE
           ELSE
               IF WS-TRAILER-OK AND
                  WS-SORT-TRAILER-COUNT NOT = WS-SORT-RECORDS-OUT
                   SET TXSM-SO-PARTIAL TO TRUE
               END-IF
               IF WS-TRAILER-OK AND
                  WS-SORT-TRAILER-SUM NOT = WS-SORT-AMOUNT-SUM
                   SET TXSM-SO-PARTIAL TO TRUE
               END-IF
           END-IF
           IF TXSM-SO-OK
               MOVE "Y" TO WS-SORT-CTRL-MATCH
           END-IF.

       PUBLISH-COUNTERS.
           MOVE WS-SORT-RECORDS-IN  TO TXSM-SO-RECORDS-PROCESSED
           MOVE WS-SORT-RECORDS-OUT TO TXSM-SO-RECORDS-SORTED
           MOVE WS-SORT-AMOUNT-SUM  TO TXSM-SO-AMOUNT-SUM
           IF TXSM-SO-OK
               MOVE "Y" TO TXSM-SO-CTRL-TOTAL-MATCH
           ELSE
               MOVE "N" TO TXSM-SO-CTRL-TOTAL-MATCH
           END-IF.

       EMIT-AUDIT-SUMMARY.
           MOVE "11-txsm-sort" TO WS-LOG-SUBSYSTEM
           MOVE "INFO " TO WS-LOG-LEVEL
           STRING "SORT-BATCH batch="
                  FUNCTION TRIM(TXSM-SI-BATCH-ID)
                  ",in=" WS-SORT-RECORDS-IN
                  ",out=" WS-SORT-RECORDS-OUT
                  ",ctrl=" TXSM-SO-CTRL-TOTAL-MATCH
                  ",status=" TXSM-SO-STATUS
                  DELIMITED BY SIZE INTO WS-LOG-MESSAGE
           PERFORM EMIT-LOG.

       EMIT-LOG.
           CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC
           ON EXCEPTION CONTINUE
           END-CALL.

       END PROGRAM TXSM-SORT-BATCH.
