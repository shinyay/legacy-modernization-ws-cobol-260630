       IDENTIFICATION DIVISION.
       PROGRAM-ID. TXVAL-VALIDATE-BATCH.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TXN-DECODED-FILE
               ASSIGN TO WS-IN-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-IN.
           SELECT TXN-VALID-FILE
               ASSIGN TO WS-VALID-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-VALID.
           SELECT TXN-ERROR-FILE
               ASSIGN TO WS-ERROR-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-ERROR.
           SELECT TXN-CHECKPOINT-FILE
               ASSIGN TO WS-CKPT-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-CKPT.

       DATA DIVISION.
       FILE SECTION.
           COPY "fd-txn-decoded.cpy".
           COPY "fd-txn-valid.cpy".
           COPY "fd-txn-error.cpy".
           COPY "fd-txn-checkpoint.cpy".

       WORKING-STORAGE SECTION.
       01  WS-IN-PATH                PIC X(80) VALUE SPACES.
       01  WS-VALID-PATH             PIC X(80) VALUE SPACES.
       01  WS-ERROR-PATH             PIC X(80) VALUE SPACES.
       01  WS-CKPT-PATH              PIC X(80) VALUE SPACES.

       01  WS-FS-IN                  PIC X(2).
       01  WS-FS-VALID               PIC X(2).
       01  WS-FS-ERROR               PIC X(2).
       01  WS-FS-CKPT                PIC X(2).

           COPY "ws-txn-decoded-record.cpy".

           COPY "ws-txn-error-record.cpy".

           COPY "ws-master-cache.cpy".

           COPY "ws-txval-state.cpy".

       01  WS-CONTROL.
           05  WS-EOF                PIC X(1) VALUE "N".
               88  WS-EOF-Y                  VALUE "Y".
           05  WS-HEADER-SEEN        PIC X(1) VALUE "N".
               88  WS-HEADER-OK              VALUE "Y".
           05  WS-TRAILER-SEEN       PIC X(1) VALUE "N".
               88  WS-TRAILER-OK             VALUE "Y".
           05  WS-EXPECTED-COUNT     PIC 9(10) VALUE 0.
           05  WS-EXPECTED-AMOUNT    PIC 9(20) VALUE 0.
           05  WS-CKPT-COUNTER       PIC 9(5)  VALUE 0.
           05  WS-CKPT-CHECKSUM      PIC X(8)  VALUE "00000000".
           05  WS-SAVED-BDATE        PIC 9(8)  VALUE 0.

       01  WS-CAL-CALL-IN.
           05  WS-CCI-DATE           PIC 9(8).
       01  WS-CAL-CALL-OUT.
           05  WS-CCO-STATUS         PIC 9(2).
           05  WS-CCO-DAY-TYPE       PIC X(1).
           05  WS-CCO-HOLIDAY-NAME   PIC X(40).
           05  WS-CCO-NEXT-DATE      PIC 9(8).

       01  WS-BR-CALL-IN.
           05  WS-BCI-CODE           PIC X(3).
           05  WS-BCI-REGION         PIC X(20) VALUE SPACES.
           05  WS-BCI-OP             PIC X(1) VALUE "L".
       01  WS-BR-CALL-OUT.
           05  WS-BCO-STATUS         PIC 9(2).
           05  WS-BCO-CODE           PIC X(3).
           05  WS-BCO-NAME-KANJI     PIC X(40).
           05  WS-BCO-NAME-KANA      PIC X(40).
           05  WS-BCO-REGION         PIC X(20).
           05  WS-BCO-STATUS-CODE    PIC X(1).

       01  WS-PROD-CALL-IN.
           05  WS-PCI-CODE           PIC X(3).
       01  WS-PROD-CALL-OUT.
           05  WS-PCO-STATUS         PIC 9(2).
           05  WS-PCO-CODE           PIC X(3).
           05  WS-PCO-NAME           PIC X(40).
           05  WS-PCO-TYPE           PIC X(1).
           05  WS-PCO-INTEREST-TYPE  PIC X(1).
           05  WS-PCO-ALLOW-OVD      PIC X(1).
           05  WS-PCO-TERM-DAYS      PIC 9(4).
           05  WS-PCO-EFF-FROM       PIC 9(8).
           05  WS-PCO-EFF-TO         PIC 9(8).

       01  WS-SCRATCH.
           05  WS-DATE-IDX           PIC 9(5).
           05  WS-DATE-TMP           PIC 9(8).
           05  WS-LOOP-I             PIC 9(5).
           05  WS-CAT                PIC X(2).
           05  WS-FOUND              PIC X(1).
           05  WS-CACHE-HIT-IDX      PIC S9(5).
           05  WS-PAYER-BRANCH       PIC 9(3).
           05  WS-PAYER-PRODUCT      PIC 9(3).
           05  WS-CMP-DATE           PIC 9(8).
           05  WS-CTRL-AMT-RUN       PIC 9(20) VALUE 0.
           05  WS-CTRL-CNT-RUN       PIC 9(10) VALUE 0.
           05  WS-TEXT-POS           PIC 9(3) VALUE 1.
           05  WS-FRAG               PIC X(20).

           COPY "shared-log-api.cpy".

       01  WS-DATE-PARTS.
           05  WS-DP-YEAR            PIC 9(4).
           05  WS-DP-MON             PIC 9(2).
           05  WS-DP-DAY             PIC 9(2).
       01  WS-DAYS-IN-MON.
           05  FILLER PIC 9(2) VALUE 31.
           05  FILLER PIC 9(2) VALUE 28.
           05  FILLER PIC 9(2) VALUE 31.
           05  FILLER PIC 9(2) VALUE 30.
           05  FILLER PIC 9(2) VALUE 31.
           05  FILLER PIC 9(2) VALUE 30.
           05  FILLER PIC 9(2) VALUE 31.
           05  FILLER PIC 9(2) VALUE 31.
           05  FILLER PIC 9(2) VALUE 30.
           05  FILLER PIC 9(2) VALUE 31.
           05  FILLER PIC 9(2) VALUE 30.
           05  FILLER PIC 9(2) VALUE 31.
       01  WS-DIM-TABLE REDEFINES WS-DAYS-IN-MON.
           05  WS-DIM OCCURS 12 TIMES PIC 9(2).
       01  WS-DATE-OK                PIC X(1).

       LINKAGE SECTION.
           COPY "tx-val-api.cpy".

       PROCEDURE DIVISION USING TXVAL-BATCH-INPUT
                                TXVAL-BATCH-OUTPUT.
       MAIN-LOGIC SECTION.
       M-START.
           PERFORM INIT-OUTPUT-AREA
           PERFORM COPY-PATHS-FROM-LINKAGE
           PERFORM LOAD-MASTER-CACHE
           IF TXVAL-INVALID-INPUT OR TXVAL-FATAL
               PERFORM EMIT-AUDIT-SUMMARY
               GOBACK
           END-IF
           PERFORM OPEN-FILES
           IF NOT TXVAL-OK AND NOT TXVAL-PARTIAL-REJECT
               PERFORM CLOSE-ALL-SAFELY
               PERFORM EMIT-AUDIT-SUMMARY
               GOBACK
           END-IF
           PERFORM PROCESS-LOOP UNTIL WS-EOF-Y
           PERFORM TRAILER-FINAL-CHECK
           PERFORM CLOSE-FILES
           PERFORM PUBLISH-COUNTERS-TO-LINKAGE
           PERFORM SET-FINAL-STATUS
           PERFORM EMIT-AUDIT-SUMMARY
           PERFORM DELETE-CHECKPOINT
           GOBACK.

       INIT-OUTPUT-AREA.
           SET TXVAL-OK TO TRUE
           MOVE 0 TO TXVAL-OUT-PROCESSED
                      TXVAL-OUT-VALIDATED
                      TXVAL-OUT-REJECTED
           MOVE 0 TO TXVAL-OUT-PRI-E001 TXVAL-OUT-PRI-E002
                      TXVAL-OUT-PRI-E003 TXVAL-OUT-PRI-E007
                      TXVAL-OUT-PRI-E008 TXVAL-OUT-PRI-E009
                      TXVAL-OUT-PRI-E010 TXVAL-OUT-PRI-E011
                      TXVAL-OUT-PRI-E012 TXVAL-OUT-PRI-E013
                      TXVAL-OUT-PRI-E014 TXVAL-OUT-PRI-E015
                      TXVAL-OUT-PRI-E016 TXVAL-OUT-PRI-E017
                      TXVAL-OUT-PRI-E018 TXVAL-OUT-PRI-E019
                      TXVAL-OUT-PRI-E099
           MOVE 0 TO TXVAL-OUT-OCC-E001 TXVAL-OUT-OCC-E002
                      TXVAL-OUT-OCC-E003 TXVAL-OUT-OCC-E007
                      TXVAL-OUT-OCC-E008 TXVAL-OUT-OCC-E009
                      TXVAL-OUT-OCC-E010 TXVAL-OUT-OCC-E011
                      TXVAL-OUT-OCC-E012 TXVAL-OUT-OCC-E013
                      TXVAL-OUT-OCC-E014 TXVAL-OUT-OCC-E015
                      TXVAL-OUT-OCC-E016 TXVAL-OUT-OCC-E017
                      TXVAL-OUT-OCC-E018 TXVAL-OUT-OCC-E019
                      TXVAL-OUT-OCC-E099
           MOVE 0 TO WS-RUN-PROCESSED WS-RUN-VALIDATED WS-RUN-REJECTED
           MOVE 0 TO WS-RUN-PRI-E001 WS-RUN-PRI-E002 WS-RUN-PRI-E003
                      WS-RUN-PRI-E007 WS-RUN-PRI-E008 WS-RUN-PRI-E009
                      WS-RUN-PRI-E010 WS-RUN-PRI-E011 WS-RUN-PRI-E012
                      WS-RUN-PRI-E013 WS-RUN-PRI-E014 WS-RUN-PRI-E015
                      WS-RUN-PRI-E016 WS-RUN-PRI-E017 WS-RUN-PRI-E018
                      WS-RUN-PRI-E019 WS-RUN-PRI-E099
           MOVE 0 TO WS-RUN-OCC-E001 WS-RUN-OCC-E002 WS-RUN-OCC-E003
                      WS-RUN-OCC-E007 WS-RUN-OCC-E008 WS-RUN-OCC-E009
                      WS-RUN-OCC-E010 WS-RUN-OCC-E011 WS-RUN-OCC-E012
                      WS-RUN-OCC-E013 WS-RUN-OCC-E014 WS-RUN-OCC-E015
                      WS-RUN-OCC-E016 WS-RUN-OCC-E017 WS-RUN-OCC-E018
                      WS-RUN-OCC-E019 WS-RUN-OCC-E099
           MOVE 0 TO WS-CTRL-AMT-RUN WS-CTRL-CNT-RUN
           MOVE 0 TO WS-CKPT-COUNTER
           MOVE "N" TO WS-EOF WS-HEADER-SEEN WS-TRAILER-SEEN.

       COPY-PATHS-FROM-LINKAGE.
           MOVE FUNCTION TRIM(TXVAL-IN-INPUT-FILENAME)
               TO WS-IN-PATH
           MOVE FUNCTION TRIM(TXVAL-IN-VALID-FILENAME)
               TO WS-VALID-PATH
           MOVE FUNCTION TRIM(TXVAL-IN-ERROR-FILENAME)
               TO WS-ERROR-PATH
           MOVE FUNCTION TRIM(TXVAL-IN-CHECKPOINT-FILENAME)
               TO WS-CKPT-PATH.

       LOAD-MASTER-CACHE.
           PERFORM LOAD-CAL-CACHE
           IF NOT WS-CAL-CACHE-OK
               SET TXVAL-INVALID-INPUT TO TRUE
               MOVE "10-txnvalidate" TO WS-LOG-SUBSYSTEM
               MOVE "INFO " TO WS-LOG-LEVEL
               MOVE "CAL-CACHE-LOAD-FAIL" TO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
               EXIT PARAGRAPH
           END-IF
           PERFORM LOAD-BR-CACHE
           IF NOT WS-BR-CACHE-OK
               SET TXVAL-INVALID-INPUT TO TRUE
               MOVE "10-txnvalidate" TO WS-LOG-SUBSYSTEM
               MOVE "INFO " TO WS-LOG-LEVEL
               MOVE "BR-CACHE-LOAD-FAIL" TO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
               EXIT PARAGRAPH
           END-IF
           PERFORM LOAD-PROD-CACHE
           IF NOT WS-PROD-CACHE-OK
               SET TXVAL-INVALID-INPUT TO TRUE
               MOVE "10-txnvalidate" TO WS-LOG-SUBSYSTEM
               MOVE "INFO " TO WS-LOG-LEVEL
               MOVE "PROD-CACHE-LOAD-FAIL" TO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
           END-IF.

       LOAD-CAL-CACHE.
           MOVE 0 TO WS-CAL-CACHE-COUNT
           PERFORM VARYING WS-DATE-IDX FROM 1 BY 1
                   UNTIL WS-DATE-IDX > 1830
               COMPUTE WS-DATE-TMP =
                       FUNCTION DATE-OF-INTEGER(
                         FUNCTION INTEGER-OF-DATE(WS-CAL-START-DATE)
                         + (WS-DATE-IDX - 1))
               MOVE WS-DATE-TMP TO WS-CCI-DATE
               CALL "CAL-LOOKUP" USING WS-CAL-CALL-IN
                                       WS-CAL-CALL-OUT
               IF WS-CCO-STATUS = 0
                   MOVE WS-DATE-TMP
                        TO WS-CAL-E-DATE(WS-DATE-IDX)
                   MOVE WS-CCO-DAY-TYPE
                        TO WS-CAL-E-DAY-TYPE(WS-DATE-IDX)
                   MOVE "Y"
                        TO WS-CAL-E-VALID-FLAG(WS-DATE-IDX)
                   ADD 1 TO WS-CAL-CACHE-COUNT
               ELSE
                   MOVE WS-DATE-TMP
                        TO WS-CAL-E-DATE(WS-DATE-IDX)
                   MOVE "N"
                        TO WS-CAL-E-VALID-FLAG(WS-DATE-IDX)
               END-IF
           END-PERFORM
           IF WS-CAL-CACHE-COUNT > 0
               SET WS-CAL-CACHE-OK TO TRUE
           END-IF.

       LOAD-BR-CACHE.
           MOVE 0 TO WS-BR-CACHE-COUNT
           PERFORM VARYING WS-LOOP-I FROM 1 BY 1 UNTIL WS-LOOP-I > 10
               MOVE WS-KNOWN-BR(WS-LOOP-I) TO WS-BCI-CODE
               MOVE "L" TO WS-BCI-OP
               CALL "BR-LOOKUP" USING WS-BR-CALL-IN
                                      WS-BR-CALL-OUT
               IF WS-BCO-STATUS = 0
                   MOVE WS-BCO-CODE
                        TO WS-BR-E-CODE(WS-LOOP-I)
                   MOVE WS-BCO-STATUS-CODE
                        TO WS-BR-E-STATUS(WS-LOOP-I)
                   MOVE "Y" TO WS-BR-E-VALID-FLAG(WS-LOOP-I)
                   ADD 1 TO WS-BR-CACHE-COUNT
               ELSE
                   MOVE WS-KNOWN-BR(WS-LOOP-I)
                        TO WS-BR-E-CODE(WS-LOOP-I)
                   MOVE "N" TO WS-BR-E-VALID-FLAG(WS-LOOP-I)
               END-IF
           END-PERFORM
           IF WS-BR-CACHE-COUNT > 0
               SET WS-BR-CACHE-OK TO TRUE
           END-IF.

       LOAD-PROD-CACHE.
           MOVE 0 TO WS-PROD-CACHE-COUNT
           PERFORM VARYING WS-LOOP-I FROM 1 BY 1 UNTIL WS-LOOP-I > 3
               MOVE WS-KNOWN-PROD(WS-LOOP-I) TO WS-PCI-CODE
               CALL "PROD-LOOKUP" USING WS-PROD-CALL-IN
                                        WS-PROD-CALL-OUT
               IF WS-PCO-STATUS = 0
                   MOVE WS-PCO-CODE
                        TO WS-PROD-E-CODE(WS-LOOP-I)
                   MOVE WS-PCO-TYPE
                        TO WS-PROD-E-TYPE(WS-LOOP-I)
                   MOVE WS-PCO-EFF-FROM
                        TO WS-PROD-E-EFF-FROM(WS-LOOP-I)
                   MOVE WS-PCO-EFF-TO
                        TO WS-PROD-E-EFF-TO(WS-LOOP-I)
                   MOVE "Y"
                        TO WS-PROD-E-VALID-FLAG(WS-LOOP-I)
                   ADD 1 TO WS-PROD-CACHE-COUNT
               ELSE
                   MOVE WS-KNOWN-PROD(WS-LOOP-I)
                        TO WS-PROD-E-CODE(WS-LOOP-I)
                   MOVE "N"
                        TO WS-PROD-E-VALID-FLAG(WS-LOOP-I)
               END-IF
           END-PERFORM
           IF WS-PROD-CACHE-COUNT > 0
               SET WS-PROD-CACHE-OK TO TRUE
           END-IF.

       OPEN-FILES.
           OPEN INPUT TXN-DECODED-FILE
           IF WS-FS-IN NOT = "00"
               DISPLAY "DBG OPEN-IN fail fs=" WS-FS-IN
                       " path=" FUNCTION TRIM(WS-IN-PATH)
               SET TXVAL-IO-FAIL TO TRUE
               EXIT PARAGRAPH
           END-IF
           OPEN OUTPUT TXN-VALID-FILE
           IF WS-FS-VALID NOT = "00"
               DISPLAY "DBG OPEN-VALID fail fs=" WS-FS-VALID
               SET TXVAL-IO-FAIL TO TRUE
               EXIT PARAGRAPH
           END-IF
           OPEN OUTPUT TXN-ERROR-FILE
           IF WS-FS-ERROR NOT = "00"
               DISPLAY "DBG OPEN-ERR fail fs=" WS-FS-ERROR
               SET TXVAL-IO-FAIL TO TRUE
           END-IF.

       CLOSE-FILES.
           CLOSE TXN-DECODED-FILE
           CLOSE TXN-VALID-FILE
           CLOSE TXN-ERROR-FILE.

       CLOSE-ALL-SAFELY.
           IF WS-FS-IN = "00"
               CLOSE TXN-DECODED-FILE
               CONTINUE
           END-IF.

       DELETE-CHECKPOINT.
           CONTINUE.

       PROCESS-LOOP.
           READ TXN-DECODED-FILE INTO TXN-DECODED-REC
               AT END
                   SET WS-EOF-Y TO TRUE
                   EXIT PARAGRAPH
           END-READ
           IF WS-FS-IN NOT = "00" AND WS-FS-IN NOT = "10"
               SET TXVAL-IO-FAIL TO TRUE
               SET WS-EOF-Y TO TRUE
               EXIT PARAGRAPH
           END-IF
           EVALUATE TRUE
               WHEN TXN-IS-HEADER
                   PERFORM PROCESS-HEADER
               WHEN TXN-IS-DETAIL
                   PERFORM PROCESS-DETAIL
               WHEN TXN-IS-TRAILER
                   PERFORM PROCESS-TRAILER
               WHEN OTHER
                   PERFORM HANDLE-UNKNOWN-TYPE
           END-EVALUATE.

       PROCESS-HEADER.
           IF WS-HEADER-OK
               MOVE "10-txnvalidate" TO WS-LOG-SUBSYSTEM
               MOVE "INFO " TO WS-LOG-LEVEL
               MOVE "DUPLICATE-HEADER" TO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
               PERFORM RESET-PER-REC
               SET WS-F-E001-SET TO TRUE
               MOVE 1 TO TE-ORIG-SEQ
               MOVE TXN-DECODED-REC TO TE-ORIG-REC
               MOVE "duplicate header"
                   TO WS-REASON-TEXT
               MOVE "E001" TO WS-PRIMARY-CODE
               SET WS-REC-REJECTED TO TRUE
               PERFORM WRITE-REJECT-RECORD
               PERFORM TALLY-PRIMARY-COUNTER
               PERFORM TALLY-OCC-COUNTERS
               ADD 1 TO WS-RUN-PROCESSED
               ADD 1 TO WS-RUN-REJECTED
               EXIT PARAGRAPH
           END-IF
           SET WS-HEADER-OK TO TRUE
           IF TDH-BATCH-ID NOT = TXVAL-IN-BATCH-ID
               MOVE "10-txnvalidate" TO WS-LOG-SUBSYSTEM
               MOVE "INFO " TO WS-LOG-LEVEL
               MOVE "HEADER-BATCH-ID-MISMATCH" TO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
               SET TXVAL-INVALID-INPUT TO TRUE
           END-IF
           MOVE TDH-BUSINESS-DATE TO WS-CMP-DATE
           PERFORM VALIDATE-GREGORIAN-DATE
           IF WS-DATE-OK = "N"
               MOVE "10-txnvalidate" TO WS-LOG-SUBSYSTEM
               MOVE "INFO " TO WS-LOG-LEVEL
               MOVE "HEADER-NON-GREGORIAN" TO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
               SET TXVAL-INVALID-INPUT TO TRUE
           END-IF
           IF TDH-BUSINESS-DATE NOT = TXVAL-IN-BUSINESS-DATE
               MOVE "10-txnvalidate" TO WS-LOG-SUBSYSTEM
               MOVE "INFO " TO WS-LOG-LEVEL
               MOVE "HEADER-BUSINESS-DATE-MISMATCH"
                   TO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
               SET TXVAL-INVALID-INPUT TO TRUE
           END-IF
           MOVE TDH-EXPECTED-COUNT TO WS-EXPECTED-COUNT
           MOVE TDH-BUSINESS-DATE  TO WS-SAVED-BDATE.

       PROCESS-DETAIL.
           ADD 1 TO WS-RUN-PROCESSED
           ADD 1 TO WS-CTRL-CNT-RUN
           ADD TDD-AMOUNT-JPY TO WS-CTRL-AMT-RUN
           PERFORM RESET-PER-REC

           IF NOT WS-HEADER-OK
               SET WS-F-E001-SET TO TRUE
           END-IF

           PERFORM CHECK-E002-CATEGORY
           PERFORM CHECK-E003-ACCOUNT-FORMAT
           PERFORM CHECK-E007-COUNTER-MISSING
           PERFORM CHECK-E008-SELF-TRANSFER
           PERFORM CHECK-E009-AMOUNT-ZERO
           PERFORM CHECK-E010-AMOUNT-LIMIT
           PERFORM CHECK-E013-CURRENCY
           PERFORM CHECK-E018-COUNTER-NON-TRANSFER
           PERFORM CHECK-MASTER-LOOKUPS
           PERFORM CHECK-E019-TD-WITHDRAW
           PERFORM AGGREGATE-FAIL-FLAGS
           IF WS-REC-REJECTED
               MOVE TDD-SEQ TO TE-ORIG-SEQ
               MOVE TXN-DECODED-REC TO TE-ORIG-REC
               PERFORM COMPOSE-REASON-TEXT
               PERFORM WRITE-REJECT-RECORD
               PERFORM TALLY-PRIMARY-COUNTER
               PERFORM TALLY-OCC-COUNTERS
               ADD 1 TO WS-RUN-REJECTED
           ELSE
               WRITE TXN-VALID-OUT-REC FROM TXN-DECODED-REC
               ADD 1 TO WS-RUN-VALIDATED
           END-IF
           PERFORM CHECKPOINT-MAYBE.

       PROCESS-TRAILER.
           SET WS-TRAILER-OK TO TRUE
           IF TDT-RECORD-COUNT NOT = WS-CTRL-CNT-RUN
               MOVE "10-txnvalidate" TO WS-LOG-SUBSYSTEM
               MOVE "INFO " TO WS-LOG-LEVEL
               MOVE "TRAILER-COUNT-MISMATCH" TO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
               SET TXVAL-INVALID-INPUT TO TRUE
           END-IF
           IF TDT-AMOUNT-SUM NOT = WS-CTRL-AMT-RUN
               MOVE "10-txnvalidate" TO WS-LOG-SUBSYSTEM
               MOVE "INFO " TO WS-LOG-LEVEL
               MOVE "TRAILER-AMOUNT-MISMATCH" TO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
               SET TXVAL-INVALID-INPUT TO TRUE
           END-IF.

       TRAILER-FINAL-CHECK.
           IF NOT WS-TRAILER-OK AND NOT TXVAL-IO-FAIL
                                AND NOT TXVAL-FATAL
               MOVE "10-txnvalidate" TO WS-LOG-SUBSYSTEM
               MOVE "INFO " TO WS-LOG-LEVEL
               MOVE "TRAILER-MISSING" TO WS-LOG-MESSAGE
               PERFORM EMIT-LOG
               SET TXVAL-INVALID-INPUT TO TRUE
           END-IF.

       HANDLE-UNKNOWN-TYPE.
           ADD 1 TO WS-RUN-PROCESSED
           PERFORM RESET-PER-REC
           SET WS-F-E001-SET TO TRUE
           MOVE WS-RUN-PROCESSED TO TE-ORIG-SEQ
           MOVE TXN-DECODED-REC TO TE-ORIG-REC
           MOVE "E001" TO WS-PRIMARY-CODE
           MOVE "E001: invalid record type"
               TO WS-REASON-TEXT
           SET WS-REC-REJECTED TO TRUE
           PERFORM WRITE-REJECT-RECORD
           PERFORM TALLY-PRIMARY-COUNTER
           PERFORM TALLY-OCC-COUNTERS
           ADD 1 TO WS-RUN-REJECTED.

       CHECK-E002-CATEGORY.
           IF NOT TDD-CAT-VALID
               SET WS-F-E002-SET TO TRUE
           END-IF.

       CHECK-E003-ACCOUNT-FORMAT.
           IF TDD-PAYER-ACCT = SPACES
               SET WS-F-E003-SET TO TRUE
           ELSE
               PERFORM CHECK-ACCT-IS-13DIGIT
                   THRU CHECK-ACCT-IS-13DIGIT-END
           END-IF
           IF TDD-PAYEE-ACCT NOT = SPACES
               IF TDD-PAYEE-ACCT(1:13) IS NOT NUMERIC
                   SET WS-F-E003-SET TO TRUE
               END-IF
           END-IF.

       CHECK-ACCT-IS-13DIGIT.
           IF TDD-PAYER-ACCT(1:13) IS NOT NUMERIC
               SET WS-F-E003-SET TO TRUE
           END-IF.
       CHECK-ACCT-IS-13DIGIT-END.
           EXIT.

       CHECK-E007-COUNTER-MISSING.
           IF TDD-CAT-REQUIRES-COUNTER AND TDD-PAYEE-ACCT = SPACES
               SET WS-F-E007-SET TO TRUE
           END-IF.

       CHECK-E008-SELF-TRANSFER.
           IF TDD-PAYEE-ACCT NOT = SPACES AND
              TDD-PAYER-ACCT = TDD-PAYEE-ACCT
               SET WS-F-E008-SET TO TRUE
           END-IF.

       CHECK-E009-AMOUNT-ZERO.
           IF TDD-AMOUNT-JPY = 0
               SET WS-F-E009-SET TO TRUE
           END-IF.

       CHECK-E010-AMOUNT-LIMIT.
           IF TDD-AMOUNT-JPY > 100000000
               SET WS-F-E010-SET TO TRUE
           END-IF.

       CHECK-E013-CURRENCY.
           IF TDD-CURRENCY NOT = "JPY"
               SET WS-F-E013-SET TO TRUE
           END-IF.

       CHECK-E018-COUNTER-NON-TRANSFER.
           IF NOT TDD-CAT-REQUIRES-COUNTER AND
              TDD-PAYEE-ACCT NOT = SPACES
               SET WS-F-E018-SET TO TRUE
           END-IF.

       CHECK-MASTER-LOOKUPS.
           MOVE WS-SAVED-BDATE TO WS-CMP-DATE
           PERFORM CAL-CACHE-LOOKUP
           IF WS-FOUND = "N"
               SET WS-F-E012-SET TO TRUE
           ELSE
               IF WS-CCO-DAY-TYPE NOT = "B"
                   SET WS-F-E012-SET TO TRUE
               END-IF
           END-IF
           MOVE TDD-BRANCH-CODE TO WS-BCI-CODE
           PERFORM BR-CACHE-LOOKUP
           IF WS-FOUND = "N"
               SET WS-F-E014-SET TO TRUE
           ELSE
               IF WS-BCO-STATUS-CODE NOT = "A"
                   SET WS-F-E014-SET TO TRUE
               END-IF
           END-IF
           MOVE TDD-PRODUCT-CODE TO WS-PCI-CODE
           PERFORM PROD-CACHE-LOOKUP
           IF WS-FOUND = "N"
               SET WS-F-E015-SET TO TRUE
           ELSE
               MOVE WS-SAVED-BDATE TO WS-CMP-DATE
               IF WS-CMP-DATE < WS-PCO-EFF-FROM
                   SET WS-F-E016-SET TO TRUE
               END-IF
               IF WS-CMP-DATE > WS-PCO-EFF-TO
                   SET WS-F-E016-SET TO TRUE
               END-IF
           END-IF.

       CHECK-E019-TD-WITHDRAW.
           IF TDD-CAT-WITHDRAW
               MOVE TDD-PRODUCT-CODE TO WS-PCI-CODE
               PERFORM PROD-CACHE-LOOKUP
               IF WS-FOUND = "Y" AND WS-PCO-TYPE = "T"
                   SET WS-F-E019-SET TO TRUE
               END-IF
           END-IF.

       CAL-CACHE-LOOKUP.
           MOVE "N" TO WS-FOUND
           IF WS-CMP-DATE < WS-CAL-START-DATE
               EXIT PARAGRAPH
           END-IF
           COMPUTE WS-DATE-IDX =
                   FUNCTION INTEGER-OF-DATE(WS-CMP-DATE) -
                   FUNCTION INTEGER-OF-DATE(WS-CAL-START-DATE) + 1
           IF WS-DATE-IDX < 1 OR WS-DATE-IDX > 1830
               EXIT PARAGRAPH
           END-IF
           IF WS-CAL-E-VALID-FLAG(WS-DATE-IDX) = "Y"
               MOVE WS-CAL-E-DAY-TYPE(WS-DATE-IDX) TO WS-CCO-DAY-TYPE
               MOVE "Y" TO WS-FOUND
           END-IF.

       BR-CACHE-LOOKUP.
           MOVE "N" TO WS-FOUND
           PERFORM VARYING WS-LOOP-I FROM 1 BY 1 UNTIL WS-LOOP-I > 10
               IF WS-BR-E-CODE(WS-LOOP-I) = WS-BCI-CODE AND
                  WS-BR-E-VALID-FLAG(WS-LOOP-I) = "Y"
                   MOVE WS-BR-E-STATUS(WS-LOOP-I)
                        TO WS-BCO-STATUS-CODE
                   MOVE "Y" TO WS-FOUND
                   EXIT PERFORM
               END-IF
           END-PERFORM.

       PROD-CACHE-LOOKUP.
           MOVE "N" TO WS-FOUND
           PERFORM VARYING WS-LOOP-I FROM 1 BY 1 UNTIL WS-LOOP-I > 3
               IF WS-PROD-E-CODE(WS-LOOP-I) = WS-PCI-CODE AND
                  WS-PROD-E-VALID-FLAG(WS-LOOP-I) = "Y"
                   MOVE WS-PROD-E-TYPE(WS-LOOP-I) TO WS-PCO-TYPE
                   MOVE WS-PROD-E-EFF-FROM(WS-LOOP-I)
                        TO WS-PCO-EFF-FROM
                   MOVE WS-PROD-E-EFF-TO(WS-LOOP-I)
                        TO WS-PCO-EFF-TO
                   MOVE "Y" TO WS-FOUND
                   EXIT PERFORM
               END-IF
           END-PERFORM.

       RESET-PER-REC.
           INITIALIZE WS-TXVAL-PER-REC
           MOVE "N" TO WS-FAIL-E001 WS-FAIL-E002 WS-FAIL-E003
                       WS-FAIL-E007 WS-FAIL-E008 WS-FAIL-E009
                       WS-FAIL-E010 WS-FAIL-E011 WS-FAIL-E012
                       WS-FAIL-E013 WS-FAIL-E014 WS-FAIL-E015
                       WS-FAIL-E016 WS-FAIL-E017 WS-FAIL-E018
                       WS-FAIL-E019 WS-FAIL-E099
                       WS-ANY-FAIL
           MOVE SPACES TO WS-PRIMARY-CODE WS-REASON-TEXT.

       AGGREGATE-FAIL-FLAGS.
           IF WS-F-E001-SET OR WS-F-E002-SET OR WS-F-E003-SET OR
              WS-F-E007-SET OR WS-F-E008-SET OR WS-F-E009-SET OR
              WS-F-E010-SET OR WS-F-E011-SET OR WS-F-E012-SET OR
              WS-F-E013-SET OR WS-F-E014-SET OR WS-F-E015-SET OR
              WS-F-E016-SET OR WS-F-E017-SET OR WS-F-E018-SET OR
              WS-F-E019-SET OR WS-F-E099-SET
               SET WS-REC-REJECTED TO TRUE
               PERFORM PICK-PRIMARY-CODE
           END-IF.

       PICK-PRIMARY-CODE.
           EVALUATE TRUE
               WHEN WS-F-E001-SET  MOVE "E001" TO WS-PRIMARY-CODE
               WHEN WS-F-E002-SET  MOVE "E002" TO WS-PRIMARY-CODE
               WHEN WS-F-E003-SET  MOVE "E003" TO WS-PRIMARY-CODE
               WHEN WS-F-E009-SET  MOVE "E009" TO WS-PRIMARY-CODE
               WHEN WS-F-E013-SET  MOVE "E013" TO WS-PRIMARY-CODE
               WHEN WS-F-E017-SET  MOVE "E017" TO WS-PRIMARY-CODE
               WHEN WS-F-E012-SET  MOVE "E012" TO WS-PRIMARY-CODE
               WHEN WS-F-E014-SET  MOVE "E014" TO WS-PRIMARY-CODE
               WHEN WS-F-E015-SET  MOVE "E015" TO WS-PRIMARY-CODE
               WHEN WS-F-E016-SET  MOVE "E016" TO WS-PRIMARY-CODE
               WHEN WS-F-E007-SET  MOVE "E007" TO WS-PRIMARY-CODE
               WHEN WS-F-E008-SET  MOVE "E008" TO WS-PRIMARY-CODE
               WHEN WS-F-E010-SET  MOVE "E010" TO WS-PRIMARY-CODE
               WHEN WS-F-E011-SET  MOVE "E011" TO WS-PRIMARY-CODE
               WHEN WS-F-E018-SET  MOVE "E018" TO WS-PRIMARY-CODE
               WHEN WS-F-E019-SET  MOVE "E019" TO WS-PRIMARY-CODE
               WHEN OTHER          MOVE "E099" TO WS-PRIMARY-CODE
           END-EVALUATE.

       COMPOSE-REASON-TEXT.
           MOVE 1 TO WS-TEXT-POS
           MOVE SPACES TO WS-REASON-TEXT
           IF WS-F-E001-SET PERFORM APPEND-E001 END-IF
           IF WS-F-E002-SET PERFORM APPEND-E002 END-IF
           IF WS-F-E003-SET PERFORM APPEND-E003 END-IF
           IF WS-F-E007-SET PERFORM APPEND-E007 END-IF
           IF WS-F-E008-SET PERFORM APPEND-E008 END-IF
           IF WS-F-E009-SET PERFORM APPEND-E009 END-IF
           IF WS-F-E010-SET PERFORM APPEND-E010 END-IF
           IF WS-F-E011-SET PERFORM APPEND-E011 END-IF
           IF WS-F-E012-SET PERFORM APPEND-E012 END-IF
           IF WS-F-E013-SET PERFORM APPEND-E013 END-IF
           IF WS-F-E014-SET PERFORM APPEND-E014 END-IF
           IF WS-F-E015-SET PERFORM APPEND-E015 END-IF
           IF WS-F-E016-SET PERFORM APPEND-E016 END-IF
           IF WS-F-E017-SET PERFORM APPEND-E017 END-IF
           IF WS-F-E018-SET PERFORM APPEND-E018 END-IF
           IF WS-F-E019-SET PERFORM APPEND-E019 END-IF
           IF WS-F-E099-SET PERFORM APPEND-E099 END-IF.

       APPEND-E001. MOVE "E001 hdr;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E002. MOVE "E002 cat;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E003. MOVE "E003 acct;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E007. MOVE "E007 ctr-miss;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E008. MOVE "E008 self;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E009. MOVE "E009 amt=0;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E010. MOVE "E010 amt-lim;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E011. MOVE "E011 bd-future;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E012. MOVE "E012 cal-nbd;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E013. MOVE "E013 ccy;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E014. MOVE "E014 br;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E015. MOVE "E015 prod-nf;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E016. MOVE "E016 prod-ina;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E017. MOVE "E017 non-greg;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E018. MOVE "E018 ctr-non-tr;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E019. MOVE "E019 td-wd;" TO WS-FRAG
                    PERFORM APPEND-FRAG.
       APPEND-E099. MOVE "E099 unexp;" TO WS-FRAG
                    PERFORM APPEND-FRAG.

       APPEND-FRAG.
           IF WS-TEXT-POS > 70
               MOVE "[TRUNC]" TO WS-REASON-TEXT(74:7)
               EXIT PARAGRAPH
           END-IF
           STRING FUNCTION TRIM(WS-FRAG) DELIMITED BY SIZE
                  " " DELIMITED BY SIZE
                  INTO WS-REASON-TEXT
                  WITH POINTER WS-TEXT-POS.

       WRITE-REJECT-RECORD.
           MOVE WS-PRIMARY-CODE TO TE-REASON-CODE
           MOVE WS-REASON-TEXT  TO TE-REASON-TEXT
           MOVE TE-ORIG-SEQ     TO TEF-ORIG-SEQ
           MOVE TE-REASON-CODE  TO TEF-REASON-CODE
           MOVE TE-REASON-TEXT  TO TEF-REASON-TEXT
           MOVE TE-ORIG-REC     TO TEF-ORIG-REC
           WRITE TXN-ERROR-FD-REC.

       TALLY-PRIMARY-COUNTER.
           EVALUATE WS-PRIMARY-CODE
               WHEN "E001" ADD 1 TO WS-RUN-PRI-E001
               WHEN "E002" ADD 1 TO WS-RUN-PRI-E002
               WHEN "E003" ADD 1 TO WS-RUN-PRI-E003
               WHEN "E007" ADD 1 TO WS-RUN-PRI-E007
               WHEN "E008" ADD 1 TO WS-RUN-PRI-E008
               WHEN "E009" ADD 1 TO WS-RUN-PRI-E009
               WHEN "E010" ADD 1 TO WS-RUN-PRI-E010
               WHEN "E011" ADD 1 TO WS-RUN-PRI-E011
               WHEN "E012" ADD 1 TO WS-RUN-PRI-E012
               WHEN "E013" ADD 1 TO WS-RUN-PRI-E013
               WHEN "E014" ADD 1 TO WS-RUN-PRI-E014
               WHEN "E015" ADD 1 TO WS-RUN-PRI-E015
               WHEN "E016" ADD 1 TO WS-RUN-PRI-E016
               WHEN "E017" ADD 1 TO WS-RUN-PRI-E017
               WHEN "E018" ADD 1 TO WS-RUN-PRI-E018
               WHEN "E019" ADD 1 TO WS-RUN-PRI-E019
               WHEN OTHER  ADD 1 TO WS-RUN-PRI-E099
           END-EVALUATE.

       TALLY-OCC-COUNTERS.
           IF WS-F-E001-SET ADD 1 TO WS-RUN-OCC-E001 END-IF
           IF WS-F-E002-SET ADD 1 TO WS-RUN-OCC-E002 END-IF
           IF WS-F-E003-SET ADD 1 TO WS-RUN-OCC-E003 END-IF
           IF WS-F-E007-SET ADD 1 TO WS-RUN-OCC-E007 END-IF
           IF WS-F-E008-SET ADD 1 TO WS-RUN-OCC-E008 END-IF
           IF WS-F-E009-SET ADD 1 TO WS-RUN-OCC-E009 END-IF
           IF WS-F-E010-SET ADD 1 TO WS-RUN-OCC-E010 END-IF
           IF WS-F-E011-SET ADD 1 TO WS-RUN-OCC-E011 END-IF
           IF WS-F-E012-SET ADD 1 TO WS-RUN-OCC-E012 END-IF
           IF WS-F-E013-SET ADD 1 TO WS-RUN-OCC-E013 END-IF
           IF WS-F-E014-SET ADD 1 TO WS-RUN-OCC-E014 END-IF
           IF WS-F-E015-SET ADD 1 TO WS-RUN-OCC-E015 END-IF
           IF WS-F-E016-SET ADD 1 TO WS-RUN-OCC-E016 END-IF
           IF WS-F-E017-SET ADD 1 TO WS-RUN-OCC-E017 END-IF
           IF WS-F-E018-SET ADD 1 TO WS-RUN-OCC-E018 END-IF
           IF WS-F-E019-SET ADD 1 TO WS-RUN-OCC-E019 END-IF
           IF WS-F-E099-SET ADD 1 TO WS-RUN-OCC-E099 END-IF.

       VALIDATE-GREGORIAN-DATE.
           MOVE "Y" TO WS-DATE-OK
           DIVIDE WS-CMP-DATE BY 10000 GIVING WS-DP-YEAR
           COMPUTE WS-DP-MON =
               FUNCTION MOD(WS-CMP-DATE / 100, 100)
           COMPUTE WS-DP-DAY = FUNCTION MOD(WS-CMP-DATE, 100)
           IF WS-DP-YEAR < 1900 OR WS-DP-YEAR > 9999
               MOVE "N" TO WS-DATE-OK
               EXIT PARAGRAPH
           END-IF
           IF WS-DP-MON < 1 OR WS-DP-MON > 12
               MOVE "N" TO WS-DATE-OK
               EXIT PARAGRAPH
           END-IF
           IF WS-DP-DAY < 1
               MOVE "N" TO WS-DATE-OK
               EXIT PARAGRAPH
           END-IF
           IF WS-DP-MON = 2
               IF (FUNCTION MOD(WS-DP-YEAR, 4) = 0 AND
                    FUNCTION MOD(WS-DP-YEAR, 100) NOT = 0) OR
                   FUNCTION MOD(WS-DP-YEAR, 400) = 0
                   IF WS-DP-DAY > 29
                       MOVE "N" TO WS-DATE-OK
                   END-IF
               ELSE
                   IF WS-DP-DAY > 28
                       MOVE "N" TO WS-DATE-OK
                   END-IF
               END-IF
           ELSE
               IF WS-DP-DAY > WS-DIM(WS-DP-MON)
                   MOVE "N" TO WS-DATE-OK
               END-IF
           END-IF.

       CHECKPOINT-MAYBE.
           ADD 1 TO WS-CKPT-COUNTER
           IF WS-CKPT-COUNTER >= 1000
               PERFORM CHECKPOINT-WRITE
               MOVE 0 TO WS-CKPT-COUNTER
           END-IF.

       CHECKPOINT-WRITE.
           IF WS-CKPT-PATH = SPACES
               EXIT PARAGRAPH
           END-IF
           OPEN OUTPUT TXN-CHECKPOINT-FILE
           IF WS-FS-CKPT NOT = "00"
               EXIT PARAGRAPH
           END-IF
           MOVE TDD-SEQ TO TC-LAST-SEQ
           MOVE "00000000" TO TC-CHECKSUM
           MOVE "OK"        TO TC-SENTINEL
           WRITE TXN-CHECKPOINT-REC
           CLOSE TXN-CHECKPOINT-FILE.

       PUBLISH-COUNTERS-TO-LINKAGE.
           MOVE WS-RUN-PROCESSED  TO TXVAL-OUT-PROCESSED
           MOVE WS-RUN-VALIDATED  TO TXVAL-OUT-VALIDATED
           MOVE WS-RUN-REJECTED   TO TXVAL-OUT-REJECTED
           MOVE WS-RUN-PRI-E001 TO TXVAL-OUT-PRI-E001
           MOVE WS-RUN-PRI-E002 TO TXVAL-OUT-PRI-E002
           MOVE WS-RUN-PRI-E003 TO TXVAL-OUT-PRI-E003
           MOVE WS-RUN-PRI-E007 TO TXVAL-OUT-PRI-E007
           MOVE WS-RUN-PRI-E008 TO TXVAL-OUT-PRI-E008
           MOVE WS-RUN-PRI-E009 TO TXVAL-OUT-PRI-E009
           MOVE WS-RUN-PRI-E010 TO TXVAL-OUT-PRI-E010
           MOVE WS-RUN-PRI-E011 TO TXVAL-OUT-PRI-E011
           MOVE WS-RUN-PRI-E012 TO TXVAL-OUT-PRI-E012
           MOVE WS-RUN-PRI-E013 TO TXVAL-OUT-PRI-E013
           MOVE WS-RUN-PRI-E014 TO TXVAL-OUT-PRI-E014
           MOVE WS-RUN-PRI-E015 TO TXVAL-OUT-PRI-E015
           MOVE WS-RUN-PRI-E016 TO TXVAL-OUT-PRI-E016
           MOVE WS-RUN-PRI-E017 TO TXVAL-OUT-PRI-E017
           MOVE WS-RUN-PRI-E018 TO TXVAL-OUT-PRI-E018
           MOVE WS-RUN-PRI-E019 TO TXVAL-OUT-PRI-E019
           MOVE WS-RUN-PRI-E099 TO TXVAL-OUT-PRI-E099
           MOVE WS-RUN-OCC-E001 TO TXVAL-OUT-OCC-E001
           MOVE WS-RUN-OCC-E002 TO TXVAL-OUT-OCC-E002
           MOVE WS-RUN-OCC-E003 TO TXVAL-OUT-OCC-E003
           MOVE WS-RUN-OCC-E007 TO TXVAL-OUT-OCC-E007
           MOVE WS-RUN-OCC-E008 TO TXVAL-OUT-OCC-E008
           MOVE WS-RUN-OCC-E009 TO TXVAL-OUT-OCC-E009
           MOVE WS-RUN-OCC-E010 TO TXVAL-OUT-OCC-E010
           MOVE WS-RUN-OCC-E011 TO TXVAL-OUT-OCC-E011
           MOVE WS-RUN-OCC-E012 TO TXVAL-OUT-OCC-E012
           MOVE WS-RUN-OCC-E013 TO TXVAL-OUT-OCC-E013
           MOVE WS-RUN-OCC-E014 TO TXVAL-OUT-OCC-E014
           MOVE WS-RUN-OCC-E015 TO TXVAL-OUT-OCC-E015
           MOVE WS-RUN-OCC-E016 TO TXVAL-OUT-OCC-E016
           MOVE WS-RUN-OCC-E017 TO TXVAL-OUT-OCC-E017
           MOVE WS-RUN-OCC-E018 TO TXVAL-OUT-OCC-E018
           MOVE WS-RUN-OCC-E019 TO TXVAL-OUT-OCC-E019
           MOVE WS-RUN-OCC-E099 TO TXVAL-OUT-OCC-E099.

       SET-FINAL-STATUS.
           EVALUATE TRUE
               WHEN TXVAL-IO-FAIL  CONTINUE
               WHEN TXVAL-FATAL    CONTINUE
               WHEN TXVAL-INVALID-INPUT CONTINUE
               WHEN WS-RUN-REJECTED > 0
                   SET TXVAL-PARTIAL-REJECT TO TRUE
               WHEN OTHER
                   SET TXVAL-OK TO TRUE
           END-EVALUATE.

       EMIT-AUDIT-SUMMARY.
           MOVE "10-txnvalidate"  TO WS-LOG-SUBSYSTEM
           MOVE "INFO "           TO WS-LOG-LEVEL
           MOVE SPACES            TO WS-LOG-MESSAGE
           STRING "VALIDATE-BATCH batch="
                  FUNCTION TRIM(TXVAL-IN-BATCH-ID)
                  ",proc=" WS-RUN-PROCESSED
                  ",valid=" WS-RUN-VALIDATED
                  ",rej=" WS-RUN-REJECTED
                  ",status=" TXVAL-BATCH-STATUS
                  DELIMITED BY SIZE
                  INTO WS-LOG-MESSAGE
           PERFORM EMIT-LOG.

       EMIT-LOG.
           CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC
           ON EXCEPTION CONTINUE
           END-CALL.

       END PROGRAM TXVAL-VALIDATE-BATCH.
