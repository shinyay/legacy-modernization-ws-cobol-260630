       IDENTIFICATION DIVISION.
       PROGRAM-ID. TXVAL-TEST.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT FIXTURE-OUT-FILE
               ASSIGN TO "/tmp/txval-test/txn-decoded.dat"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-FIX.

       DATA DIVISION.
       FILE SECTION.
       FD  FIXTURE-OUT-FILE.
       01  FIX-REC               PIC X(600).

       WORKING-STORAGE SECTION.
       01  WS-FS-FIX             PIC X(2).

       01  WS-CNT.
           05  WS-N PIC 9(3) VALUE 0.
           05  WS-P PIC 9(3) VALUE 0.
           05  WS-F PIC 9(3) VALUE 0.

       01  WS-BUILD-HEADER.
           05  BLD-H-TYPE        PIC X(1) VALUE "H".
           05  BLD-H-BATCH       PIC X(14).
           05  BLD-H-BDATE       PIC 9(8).
           05  BLD-H-SRC         PIC X(20) VALUE "EBCDIC_BATCH".
           05  BLD-H-EXPECTED    PIC 9(10).
           05  BLD-H-CHKSUM      PIC X(40) VALUE
                                      "0000000000000000000000000000000000000000".
           05  BLD-H-FILLER      PIC X(507) VALUE SPACES.

       01  WS-BUILD-DETAIL.
           05  BLD-D-TYPE        PIC X(1) VALUE "D".
           05  BLD-D-SEQ         PIC 9(10) VALUE 1.
           05  BLD-D-CAT         PIC X(2)  VALUE "10".
           05  BLD-D-AMOUNT      PIC 9(15) VALUE 1000.
           05  BLD-D-CCY         PIC X(3)  VALUE "JPY".
           05  BLD-D-PAYER       PIC X(13) VALUE "0010010000001".
           05  BLD-D-PAYEE       PIC X(13) VALUE SPACES.
           05  BLD-D-BR          PIC 9(3)  VALUE 001.
           05  BLD-D-PROD        PIC 9(3)  VALUE 001.
           05  BLD-D-DESC        PIC X(120) VALUE SPACES.
           05  BLD-D-SRC-BANK    PIC X(4)  VALUE "0001".
           05  BLD-D-SRC-BR      PIC X(3)  VALUE "001".
           05  BLD-D-ORIG-SEQ    PIC 9(10) VALUE 1.
           05  BLD-D-FILLER      PIC X(400) VALUE SPACES.

       01  WS-BUILD-TRAILER.
           05  BLD-T-TYPE        PIC X(1) VALUE "T".
           05  BLD-T-COUNT       PIC 9(10).
           05  BLD-T-AMTSUM      PIC 9(20).
           05  BLD-T-CHKSUM      PIC X(40) VALUE
                                      "0000000000000000000000000000000000000000".
           05  BLD-T-FILLER      PIC X(529) VALUE SPACES.

           COPY "tx-val-api.cpy".

       01  WS-PATHS.
           05  WS-INPUT-P  PIC X(80) VALUE
               "/tmp/txval-test/txn-decoded.dat".
           05  WS-VALID-P  PIC X(80) VALUE
               "/tmp/txval-test/txn-valid.dat".
           05  WS-ERROR-P  PIC X(80) VALUE
               "/tmp/txval-test/txn-error.dat".
           05  WS-CKPT-P   PIC X(80) VALUE
               "/tmp/txval-test/txnvalidate-20260612-001.ckpt".

       01  WS-TC-NUM         PIC 9(3) VALUE 0.

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 10-txnvalidate unit tests (Phase 4a) ==="
           PERFORM PREP-TMP-DIR

           PERFORM TC01-HAPPY-DEPOSIT
           PERFORM TC02-HAPPY-WITHDRAW
           PERFORM TC03-HAPPY-TRANSFER
           PERFORM TC04-HAPPY-WIRE
           PERFORM TC05-EMPTY-HDT

           PERFORM TC06-E001-BAD-TYPE
           PERFORM TC07-E002-BAD-CAT
           PERFORM TC08-E003-NONNUM
           PERFORM TC09-E007-COUNTER-MISSING
           PERFORM TC10-E008-SELF
           PERFORM TC11-E009-AMOUNT-ZERO
           PERFORM TC12-E010-AMOUNT-LIMIT
           PERFORM TC13-E012-CAL-WEEKEND
           PERFORM TC14-E013-CCY
           PERFORM TC15-E014-BR-UNKNOWN
           PERFORM TC16-E015-PROD-UNKNOWN
           PERFORM TC17-E018-COUNTER-NON-TR
           PERFORM TC18-E019-TD-WITHDRAW

           PERFORM TC19-MULTI-FAIL
           PERFORM TC20-MULTI-RECORD
           PERFORM TC21-TRAILER-COUNT-MISMATCH
           PERFORM TC22-TRAILER-AMOUNT-MISMATCH
           PERFORM TC23-STATUS-PARTIAL-REJECT
           PERFORM TC24-STATUS-ALL-OK
           PERFORM TC25-BATCH-ID-MISMATCH
           PERFORM TC26-BDATE-MISMATCH

           PERFORM TC27-LARGE-AMOUNT-OK
           PERFORM TC28-3-RECS-ALL-VALID
           PERFORM TC29-MIXED-VALID-REJECT
           PERFORM TC30-WIRE-NO-COUNTER
           PERFORM TC31-DEPOSIT-WITH-COUNTER

           DISPLAY "=== Total: " WS-N
                   " | PASS: " WS-P
                   " | FAIL: " WS-F
           IF WS-F > 0
               STOP RUN RETURNING 1
           END-IF
           STOP RUN.

       PREP-TMP-DIR.
           CALL "SYSTEM" USING "mkdir -p /tmp/txval-test".

       OPEN-FIXTURE.
           OPEN OUTPUT FIXTURE-OUT-FILE.

       CLOSE-FIXTURE.
           CLOSE FIXTURE-OUT-FILE.

       WRITE-HEADER-DEFAULT.
           MOVE "BATCH-202606-01" TO BLD-H-BATCH
           MOVE 20260612          TO BLD-H-BDATE
           WRITE FIX-REC FROM WS-BUILD-HEADER.

       WRITE-HEADER-EXPECT.
           MOVE "BATCH-202606-01" TO BLD-H-BATCH
           MOVE 20260612          TO BLD-H-BDATE
           WRITE FIX-REC FROM WS-BUILD-HEADER.

       WRITE-DETAIL-CURRENT.
           WRITE FIX-REC FROM WS-BUILD-DETAIL.

       WRITE-TRAILER-CNT-AMT.
           WRITE FIX-REC FROM WS-BUILD-TRAILER.

       INIT-DETAIL-DEPOSIT.
           MOVE 1                TO BLD-D-SEQ
           MOVE "10"             TO BLD-D-CAT
           MOVE 1000             TO BLD-D-AMOUNT
           MOVE "JPY"            TO BLD-D-CCY
           MOVE "0010010000001"  TO BLD-D-PAYER
           MOVE SPACES           TO BLD-D-PAYEE
           MOVE 001              TO BLD-D-BR
           MOVE 001              TO BLD-D-PROD
           MOVE SPACES           TO BLD-D-DESC
           MOVE "0001"           TO BLD-D-SRC-BANK
           MOVE "001"            TO BLD-D-SRC-BR
           MOVE 1                TO BLD-D-ORIG-SEQ.

       INIT-DETAIL-TRANSFER.
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE "30"             TO BLD-D-CAT
           MOVE "0010010000002"  TO BLD-D-PAYEE.

       INIT-DETAIL-WIRE.
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE "40"             TO BLD-D-CAT
           MOVE "0010010000002"  TO BLD-D-PAYEE.

       INIT-DETAIL-WITHDRAW.
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE "20"             TO BLD-D-CAT.

       CALL-VALIDATE.
           MOVE "BATCH-202606-01" TO TXVAL-IN-BATCH-ID
           MOVE 20260612          TO TXVAL-IN-BUSINESS-DATE
           MOVE WS-INPUT-P        TO TXVAL-IN-INPUT-FILENAME
           MOVE WS-VALID-P        TO TXVAL-IN-VALID-FILENAME
           MOVE WS-ERROR-P        TO TXVAL-IN-ERROR-FILENAME
           MOVE WS-CKPT-P         TO TXVAL-IN-CHECKPOINT-FILENAME
           CALL "TXVAL-VALIDATE-BATCH"
                USING TXVAL-BATCH-INPUT TXVAL-BATCH-OUTPUT.

       TC01-HAPPY-DEPOSIT.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-BATCH-STATUS = "00" AND
              TXVAL-OUT-VALIDATED = 1 AND
              TXVAL-OUT-REJECTED = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " happy deposit"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " st=" TXVAL-BATCH-STATUS
                       " val=" TXVAL-OUT-VALIDATED
                       " rej=" TXVAL-OUT-REJECTED
           END-IF.

       TC02-HAPPY-WITHDRAW.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-WITHDRAW
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-BATCH-STATUS = "00" AND
              TXVAL-OUT-VALIDATED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " happy withdraw"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXVAL-BATCH-STATUS
                        " val=" TXVAL-OUT-VALIDATED
                        " rej=" TXVAL-OUT-REJECTED
           END-IF.

       TC03-HAPPY-TRANSFER.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-TRANSFER
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-BATCH-STATUS = "00" AND
              TXVAL-OUT-VALIDATED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " happy transfer"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " val=" TXVAL-OUT-VALIDATED
                        " rej=" TXVAL-OUT-REJECTED
           END-IF.

       TC04-HAPPY-WIRE.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-WIRE
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-BATCH-STATUS = "00" AND
              TXVAL-OUT-VALIDATED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " happy wire"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " val=" TXVAL-OUT-VALIDATED
                        " rej=" TXVAL-OUT-REJECTED
           END-IF.

       TC05-EMPTY-HDT.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 0 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           MOVE 0 TO BLD-T-COUNT
           MOVE 0 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-BATCH-STATUS = "00" AND
              TXVAL-OUT-VALIDATED = 0 AND
              TXVAL-OUT-REJECTED = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " empty HDT"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXVAL-BATCH-STATUS
                        " val=" TXVAL-OUT-VALIDATED
                        " rej=" TXVAL-OUT-REJECTED
           END-IF.

       TC06-E001-BAD-TYPE.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           MOVE SPACES TO FIX-REC
           MOVE "X" TO FIX-REC(1:1)
           WRITE FIX-REC
           MOVE 1 TO BLD-T-COUNT
           MOVE 0 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-PRI-E001 >= 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " E001 bad type"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " E001=" TXVAL-OUT-PRI-E001
                        " rej=" TXVAL-OUT-REJECTED
           END-IF.

       TC07-E002-BAD-CAT.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE "99" TO BLD-D-CAT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-PRI-E002 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " E002 bad cat"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " E002=" TXVAL-OUT-PRI-E002
           END-IF.

       TC08-E003-NONNUM.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE "ABCDEFGHIJKLM" TO BLD-D-PAYER
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-PRI-E003 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " E003 non-numeric"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " E003=" TXVAL-OUT-PRI-E003
           END-IF.

       TC09-E007-COUNTER-MISSING.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE "30" TO BLD-D-CAT
           MOVE SPACES TO BLD-D-PAYEE
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-PRI-E007 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " E007 counter miss"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " E007=" TXVAL-OUT-PRI-E007
           END-IF.

       TC10-E008-SELF.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-TRANSFER
           MOVE BLD-D-PAYER TO BLD-D-PAYEE
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-PRI-E008 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " E008 self"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " E008=" TXVAL-OUT-PRI-E008
           END-IF.

       TC11-E009-AMOUNT-ZERO.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE 0 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 0 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-PRI-E009 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " E009 amount=0"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " E009=" TXVAL-OUT-PRI-E009
           END-IF.

       TC12-E010-AMOUNT-LIMIT.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE 200000000 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 200000000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-PRI-E010 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " E010 amt-limit"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " E010=" TXVAL-OUT-PRI-E010
           END-IF.

       TC13-E012-CAL-WEEKEND.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           MOVE "BATCH-202606-02" TO BLD-H-BATCH
           MOVE 20260614 TO BLD-H-BDATE
           WRITE FIX-REC FROM WS-BUILD-HEADER
           PERFORM INIT-DETAIL-DEPOSIT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           MOVE "BATCH-202606-02" TO TXVAL-IN-BATCH-ID
           MOVE 20260614          TO TXVAL-IN-BUSINESS-DATE
           MOVE WS-INPUT-P        TO TXVAL-IN-INPUT-FILENAME
           MOVE WS-VALID-P        TO TXVAL-IN-VALID-FILENAME
           MOVE WS-ERROR-P        TO TXVAL-IN-ERROR-FILENAME
           MOVE WS-CKPT-P         TO TXVAL-IN-CHECKPOINT-FILENAME
           CALL "TXVAL-VALIDATE-BATCH"
                USING TXVAL-BATCH-INPUT TXVAL-BATCH-OUTPUT
           IF TXVAL-OUT-PRI-E012 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " E012 cal weekend"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " E012=" TXVAL-OUT-PRI-E012
                        " val=" TXVAL-OUT-VALIDATED
                        " rej=" TXVAL-OUT-REJECTED
           END-IF.

       TC14-E013-CCY.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE "USD" TO BLD-D-CCY
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-PRI-E013 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " E013 ccy"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " E013=" TXVAL-OUT-PRI-E013
           END-IF.

       TC15-E014-BR-UNKNOWN.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE 999 TO BLD-D-BR
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-PRI-E014 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " E014 br unknown"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " E014=" TXVAL-OUT-PRI-E014
           END-IF.

       TC16-E015-PROD-UNKNOWN.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE 099 TO BLD-D-PROD
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-PRI-E015 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " E015 prod unknown"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " E015=" TXVAL-OUT-PRI-E015
           END-IF.

       TC17-E018-COUNTER-NON-TR.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE "0010010000002" TO BLD-D-PAYEE
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-PRI-E018 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " E018 counter non-tr"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " E018=" TXVAL-OUT-PRI-E018
           END-IF.

       TC18-E019-TD-WITHDRAW.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-WITHDRAW
           MOVE 002 TO BLD-D-PROD
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-PRI-E019 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " E019 TD withdraw"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " E019=" TXVAL-OUT-PRI-E019
                        " val=" TXVAL-OUT-VALIDATED
                        " rej=" TXVAL-OUT-REJECTED
           END-IF.

       TC19-MULTI-FAIL.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE 0 TO BLD-D-AMOUNT
           MOVE "USD" TO BLD-D-CCY
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 0 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-REJECTED = 1 AND
              TXVAL-OUT-PRI-E009 = 1 AND
              TXVAL-OUT-OCC-E009 = 1 AND
              TXVAL-OUT-OCC-E013 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " multi-fail rec"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " pri9=" TXVAL-OUT-PRI-E009
                        " occ9=" TXVAL-OUT-OCC-E009
                        " occ13=" TXVAL-OUT-OCC-E013
                        " rej=" TXVAL-OUT-REJECTED
           END-IF.

       TC20-MULTI-RECORD.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 3 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE 2 TO BLD-D-SEQ
           MOVE 500 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE 3 TO BLD-D-SEQ
           MOVE 750 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 3 TO BLD-T-COUNT
           MOVE 2250 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-VALIDATED = 3 AND
              TXVAL-OUT-REJECTED = 0 AND
              TXVAL-OUT-PROCESSED = 3
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " 3-record batch"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " val=" TXVAL-OUT-VALIDATED
                        " proc=" TXVAL-OUT-PROCESSED
           END-IF.

       TC21-TRAILER-COUNT-MISMATCH.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 5 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-BATCH-STATUS = "08"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " trailer cnt mismatch"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXVAL-BATCH-STATUS
           END-IF.

       TC22-TRAILER-AMOUNT-MISMATCH.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 9999 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-BATCH-STATUS = "08"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " trailer amt mismatch"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXVAL-BATCH-STATUS
           END-IF.

       TC23-STATUS-PARTIAL-REJECT.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 2 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE 2 TO BLD-D-SEQ
           MOVE 0 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 2 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-BATCH-STATUS = "04" AND
              TXVAL-OUT-VALIDATED = 1 AND
              TXVAL-OUT-REJECTED = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " partial reject"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXVAL-BATCH-STATUS
                        " val=" TXVAL-OUT-VALIDATED
                        " rej=" TXVAL-OUT-REJECTED
           END-IF.

       TC24-STATUS-ALL-OK.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-BATCH-STATUS = "00"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " status=00 all ok"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXVAL-BATCH-STATUS
           END-IF.

       TC25-BATCH-ID-MISMATCH.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           MOVE "BATCH-WRONG-ID" TO BLD-H-BATCH
           MOVE 20260612 TO BLD-H-BDATE
           WRITE FIX-REC FROM WS-BUILD-HEADER
           PERFORM INIT-DETAIL-DEPOSIT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-BATCH-STATUS = "08"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " batch-id mismatch"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXVAL-BATCH-STATUS
           END-IF.

       TC26-BDATE-MISMATCH.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           MOVE "BATCH-202606-01" TO BLD-H-BATCH
           MOVE 20260615 TO BLD-H-BDATE
           WRITE FIX-REC FROM WS-BUILD-HEADER
           PERFORM INIT-DETAIL-DEPOSIT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-BATCH-STATUS = "08"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " bdate mismatch"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXVAL-BATCH-STATUS
           END-IF.

       TC27-LARGE-AMOUNT-OK.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE 99999999 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 99999999 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-VALIDATED = 1 AND TXVAL-OUT-REJECTED = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " 99.9M ok"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " val=" TXVAL-OUT-VALIDATED
                        " rej=" TXVAL-OUT-REJECTED
           END-IF.

       TC28-3-RECS-ALL-VALID.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 3 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM INIT-DETAIL-WITHDRAW
           MOVE 2 TO BLD-D-SEQ
           MOVE 100 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM INIT-DETAIL-TRANSFER
           MOVE 3 TO BLD-D-SEQ
           MOVE 200 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 3 TO BLD-T-COUNT
           MOVE 1300 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-VALIDATED = 3
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " 3 mixed cats valid"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " val=" TXVAL-OUT-VALIDATED
                        " rej=" TXVAL-OUT-REJECTED
           END-IF.

       TC29-MIXED-VALID-REJECT.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 3 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE 2 TO BLD-D-SEQ
           MOVE 99 TO BLD-D-CAT
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE 3 TO BLD-D-SEQ
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 3 TO BLD-T-COUNT
           MOVE 3000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-VALIDATED = 2 AND TXVAL-OUT-REJECTED = 1 AND
              TXVAL-BATCH-STATUS = "04"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " mixed 2 valid 1 rej"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " val=" TXVAL-OUT-VALIDATED
                        " rej=" TXVAL-OUT-REJECTED
                        " st=" TXVAL-BATCH-STATUS
           END-IF.

       TC30-WIRE-NO-COUNTER.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE "40" TO BLD-D-CAT
           MOVE SPACES TO BLD-D-PAYEE
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-PRI-E007 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " wire no counter"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " E007=" TXVAL-OUT-PRI-E007
           END-IF.

       TC31-DEPOSIT-WITH-COUNTER.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEPOSIT
           MOVE "0010010000002" TO BLD-D-PAYEE
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-VALIDATE
           IF TXVAL-OUT-PRI-E018 = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " deposit with counter"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " E018=" TXVAL-OUT-PRI-E018
           END-IF.

       END PROGRAM TXVAL-TEST.
