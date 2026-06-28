       IDENTIFICATION DIVISION.
       PROGRAM-ID. TXSM-TEST.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT FIXTURE-OUT-FILE
               ASSIGN TO WS-FIX-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-FIX.
           SELECT VERIFY-IN-FILE
               ASSIGN TO WS-VER-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS-VER.
           SELECT SUM-WRITE-FILE
               ASSIGN TO WS-SUM-WRITE-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS  IS WS-FS-SUMW.

       DATA DIVISION.
       FILE SECTION.
       FD  FIXTURE-OUT-FILE.
       01  FIX-REC               PIC X(600).
       FD  VERIFY-IN-FILE.
       01  VER-REC               PIC X(600).
       FD  SUM-WRITE-FILE.
       01  SUM-WRITE-REC         PIC X(200).

       WORKING-STORAGE SECTION.
       01  WS-FIX-PATH           PIC X(80) VALUE SPACES.
       01  WS-VER-PATH           PIC X(80) VALUE SPACES.
       01  WS-SUM-WRITE-PATH     PIC X(80) VALUE
           "/tmp/txsm-test/txn-summary.dat".
       01  WS-FS-FIX             PIC X(2).
       01  WS-FS-VER             PIC X(2).
       01  WS-FS-SUMW            PIC X(2).
       01  WS-SUM-BUF            PIC X(200).

       01  WS-CNT.
           05  WS-N PIC 9(3) VALUE 0.
           05  WS-P PIC 9(3) VALUE 0.
           05  WS-F PIC 9(3) VALUE 0.

       01  WS-BUILD-HEADER.
           05  BLD-H-TYPE        PIC X(1) VALUE "H".
           05  BLD-H-BATCH       PIC X(14).
           05  BLD-H-BDATE       PIC 9(8).
           05  BLD-H-SRC         PIC X(20) VALUE "11-TEST".
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

       01  WS-VERIFY-D.
           05  WV-TYPE           PIC X(1).
           05  WV-SEQ            PIC 9(10).
           05  WV-CAT            PIC X(2).
           05  WV-AMOUNT         PIC 9(15).
           05  WV-CCY            PIC X(3).
           05  WV-PAYER          PIC X(13).
           05  WV-FILLER         PIC X(556).

           COPY "tx-sm-api.cpy".

       01  WS-PATHS.
           05  WS-VALID-P  PIC X(80) VALUE
               "/tmp/txsm-test/txn-valid.dat".
           05  WS-SORTED-P PIC X(80) VALUE
               "/tmp/txsm-test/txn-sorted.dat".
           05  WS-RECON-P  PIC X(80) VALUE
               "/tmp/txsm-test/txn-recon-prev.dat".
           05  WS-READY-P  PIC X(80) VALUE
               "/tmp/txsm-test/txn-ready.dat".
           05  WS-ERR-P    PIC X(80) VALUE
               "/tmp/txsm-test/txn-error.dat".
           05  WS-CKPT-P   PIC X(80) VALUE
               "/tmp/txsm-test/cp.ckpt".
           05  WS-TEMP-P   PIC X(80) VALUE
               "/tmp/txsm-test/txn-ready-d-only.tmp".
           05  WS-SUM-P    PIC X(80) VALUE
               "/tmp/txsm-test/txn-summary.dat".
           05  WS-RPT-P    PIC X(80) VALUE
               "/tmp/txsm-test/txn-summary.rpt".

       01  WS-TC-NUM         PIC 9(3) VALUE 0.

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 11-txnsortmerge unit tests (Phase 4b) ==="
           PERFORM PREP-TMP-DIR

           PERFORM TC01-SORT-HAPPY-1-D
           PERFORM TC02-SORT-MULTI-D-REORDER
           PERFORM TC03-SORT-EMPTY-D
           PERFORM TC04-SORT-CONFORMIST-PRESERVE
           PERFORM TC05-SORT-CTRL-TOTAL-MATCH
           PERFORM TC06-SORT-CTRL-WARN
           PERFORM TC07-SORT-MISSING-INPUT
           PERFORM TC08-SORT-LOSSLESS-VERIFY

           PERFORM TC09-MERGE-EMPTY-RECON
           PERFORM TC10-MERGE-DISJOINT-RECON
           PERFORM TC11-MERGE-INTERLEAVED
           PERFORM TC12-MERGE-DUPLICATE-E050
           PERFORM TC13-MERGE-RECON-VIOLATION
           PERFORM TC14-MERGE-ALL-RECON-NO-SORTED
           PERFORM TC15-MERGE-ALL-SORTED-NO-RECON
           PERFORM TC16-MERGE-CONSERVATION-OK
           PERFORM TC17-MERGE-BOTH-EMPTY
           PERFORM TC18-MERGE-HEADER-COMBINE

           PERFORM TC19-REPORT-BOTH-PHASES
           PERFORM TC20-REPORT-SORT-ONLY
           PERFORM TC21-REPORT-EMPTY-SUMMARY
           PERFORM TC22-REPORT-CONSERVATION-VERIFY

           DISPLAY "=== Total: " WS-N
                   " | PASS: " WS-P
                   " | FAIL: " WS-F
           IF WS-F > 0
               STOP RUN RETURNING 1
           END-IF
           STOP RUN.

       PREP-TMP-DIR.
           CALL "SYSTEM" USING "mkdir -p /tmp/txsm-test".

       CLEANUP-TEST-FILES.
           CALL "SYSTEM" USING "rm -f /tmp/txsm-test/txn-valid.dat"
           CALL "SYSTEM" USING "rm -f /tmp/txsm-test/txn-sorted.dat"
           CALL "SYSTEM" USING "rm -f /tmp/txsm-test/txn-ready.dat"
           CALL "SYSTEM" USING "rm -f /tmp/txsm-test/txn-error.dat"
           CALL "SYSTEM" USING "rm -f /tmp/txsm-test/txn-recon-prev.dat"
           CALL "SYSTEM" USING
                "rm -f /tmp/txsm-test/txn-ready-d-only.tmp".

       CLEANUP-REPORT-FILES.
           CALL "SYSTEM" USING "rm -f /tmp/txsm-test/txn-summary.dat"
           CALL "SYSTEM" USING "rm -f /tmp/txsm-test/txn-summary.rpt".

       WRITE-SUMMARY-SORT-LINE.
           OPEN OUTPUT SUM-WRITE-FILE
           MOVE "SORT-PHASE in=3 out=3 ctrl=Y" TO SUM-WRITE-REC
           WRITE SUM-WRITE-REC
           CLOSE SUM-WRITE-FILE.

       WRITE-SUMMARY-BOTH-LINES.
           OPEN OUTPUT SUM-WRITE-FILE
           MOVE "SORT-PHASE in=3 out=3 ctrl=Y" TO SUM-WRITE-REC
           WRITE SUM-WRITE-REC
           MOVE
            "MERGE-PHASE sorted=3 recon=2 out=5 dup=0"
                TO SUM-WRITE-REC
           WRITE SUM-WRITE-REC
           CLOSE SUM-WRITE-FILE.

       WRITE-SUMMARY-BOTH-WITH-DUP.
           OPEN OUTPUT SUM-WRITE-FILE
           MOVE "SORT-PHASE in=3 out=3 ctrl=Y" TO SUM-WRITE-REC
           WRITE SUM-WRITE-REC
           MOVE
            "MERGE-PHASE sorted=3 recon=2 out=3 dup=2"
                TO SUM-WRITE-REC
           WRITE SUM-WRITE-REC
           CLOSE SUM-WRITE-FILE.

       WRITE-SUMMARY-EMPTY.
           OPEN OUTPUT SUM-WRITE-FILE
           CLOSE SUM-WRITE-FILE.

       OPEN-FIXTURE-VALID.
           MOVE WS-VALID-P TO WS-FIX-PATH
           OPEN OUTPUT FIXTURE-OUT-FILE.

       OPEN-FIXTURE-SORTED.
           MOVE WS-SORTED-P TO WS-FIX-PATH
           OPEN OUTPUT FIXTURE-OUT-FILE.

       OPEN-FIXTURE-RECON.
           MOVE WS-RECON-P TO WS-FIX-PATH
           OPEN OUTPUT FIXTURE-OUT-FILE.

       CLOSE-FIXTURE.
           CLOSE FIXTURE-OUT-FILE.

       WRITE-HEADER-DEFAULT.
           MOVE "BATCH-11-TEST01" TO BLD-H-BATCH
           MOVE 20260612          TO BLD-H-BDATE
           WRITE FIX-REC FROM WS-BUILD-HEADER.

       WRITE-DETAIL-CURRENT.
           WRITE FIX-REC FROM WS-BUILD-DETAIL.

       WRITE-TRAILER-CNT-AMT.
           WRITE FIX-REC FROM WS-BUILD-TRAILER.

       INIT-DETAIL-DEFAULT.
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

       CALL-SORT.
           MOVE "BATCH-11-TEST01" TO TXSM-SI-BATCH-ID
           MOVE 20260612          TO TXSM-SI-BUSINESS-DATE
           MOVE WS-VALID-P        TO TXSM-SI-INPUT-FILENAME
           MOVE WS-SORTED-P       TO TXSM-SI-OUTPUT-FILENAME
           MOVE WS-CKPT-P         TO TXSM-SI-CHECKPOINT-FILENAME
           CALL "TXSM-SORT-BATCH"
                USING TXSM-SORT-INPUT TXSM-SORT-OUTPUT.

       CALL-MERGE.
           MOVE "BATCH-11-TEST01" TO TXSM-MI-BATCH-ID
           MOVE 20260612          TO TXSM-MI-BUSINESS-DATE
           MOVE WS-SORTED-P       TO TXSM-MI-SORTED-FILENAME
           MOVE WS-RECON-P        TO TXSM-MI-RECON-PREV-FILENAME
           MOVE WS-READY-P        TO TXSM-MI-READY-FILENAME
           MOVE WS-ERR-P          TO TXSM-MI-ERROR-FILENAME
           MOVE WS-CKPT-P         TO TXSM-MI-CHECKPOINT-FILENAME
           MOVE WS-TEMP-P         TO TXSM-MI-TEMP-FILENAME
           CALL "TXSM-MERGE-BATCH"
                USING TXSM-MERGE-INPUT TXSM-MERGE-OUTPUT.

       TC01-SORT-HAPPY-1-D.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE-VALID
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEFAULT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-SORT
           IF TXSM-SO-STATUS = "00" AND
              TXSM-SO-RECORDS-PROCESSED = 1 AND
              TXSM-SO-RECORDS-SORTED = 1 AND
              TXSM-SO-CTRL-TOTAL-MATCH = "Y"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " sort 1 D happy"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-SO-STATUS
                        " in=" TXSM-SO-RECORDS-PROCESSED
                        " out=" TXSM-SO-RECORDS-SORTED
           END-IF.

       TC02-SORT-MULTI-D-REORDER.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE-VALID
           MOVE 3 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 1 TO BLD-D-SEQ
           MOVE "0010010000003" TO BLD-D-PAYER
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 2 TO BLD-D-SEQ
           MOVE 500 TO BLD-D-AMOUNT
           MOVE "0010010000001" TO BLD-D-PAYER
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 3 TO BLD-D-SEQ
           MOVE 250 TO BLD-D-AMOUNT
           MOVE "0010010000002" TO BLD-D-PAYER
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 3 TO BLD-T-COUNT
           MOVE 1750 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-SORT
           IF TXSM-SO-STATUS = "00" AND
              TXSM-SO-RECORDS-SORTED = 3 AND
              TXSM-SO-AMOUNT-SUM = 1750
               PERFORM VERIFY-SORT-ORDER-3
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-SO-STATUS
                        " out=" TXSM-SO-RECORDS-SORTED
                        " sum=" TXSM-SO-AMOUNT-SUM
           END-IF.

       VERIFY-SORT-ORDER-3.
           MOVE WS-SORTED-P TO WS-VER-PATH
           OPEN INPUT VERIFY-IN-FILE
           READ VERIFY-IN-FILE INTO VER-REC AT END CONTINUE END-READ
           READ VERIFY-IN-FILE INTO WS-VERIFY-D AT END CONTINUE END-READ
           IF WV-PAYER NOT = "0010010000001"
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " 1st payer=" WV-PAYER " expected 001"
               CLOSE VERIFY-IN-FILE
               EXIT PARAGRAPH
           END-IF
           READ VERIFY-IN-FILE INTO WS-VERIFY-D AT END CONTINUE END-READ
           IF WV-PAYER NOT = "0010010000002"
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " 2nd payer=" WV-PAYER " expected 002"
               CLOSE VERIFY-IN-FILE
               EXIT PARAGRAPH
           END-IF
           READ VERIFY-IN-FILE INTO WS-VERIFY-D AT END CONTINUE END-READ
           IF WV-PAYER NOT = "0010010000003"
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM
                       " 3rd payer=" WV-PAYER " expected 003"
               CLOSE VERIFY-IN-FILE
               EXIT PARAGRAPH
           END-IF
           CLOSE VERIFY-IN-FILE
           ADD 1 TO WS-P
           DISPLAY "  [PASS] " WS-TC-NUM " sort reorder 3 D ascending".

       TC03-SORT-EMPTY-D.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE-VALID
           MOVE 0 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           MOVE 0 TO BLD-T-COUNT
           MOVE 0 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-SORT
           IF TXSM-SO-STATUS = "00" AND
              TXSM-SO-RECORDS-PROCESSED = 0 AND
              TXSM-SO-RECORDS-SORTED = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " sort empty D"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-SO-STATUS
           END-IF.

       TC04-SORT-CONFORMIST-PRESERVE.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE-VALID
           MOVE 1 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 12345 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 12345 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-SORT
           MOVE WS-SORTED-P TO WS-VER-PATH
           OPEN INPUT VERIFY-IN-FILE
           READ VERIFY-IN-FILE INTO VER-REC AT END CONTINUE END-READ
           READ VERIFY-IN-FILE INTO WS-VERIFY-D AT END CONTINUE END-READ
           CLOSE VERIFY-IN-FILE
           IF TXSM-SO-STATUS = "00" AND WV-AMOUNT = 12345
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " conformist preserve"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-SO-STATUS " amt=" WV-AMOUNT
           END-IF.

       TC05-SORT-CTRL-TOTAL-MATCH.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE-VALID
           MOVE 2 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 100 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 2 TO BLD-D-SEQ
           MOVE 200 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 2 TO BLD-T-COUNT
           MOVE 300 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-SORT
           IF TXSM-SO-STATUS = "00" AND
              TXSM-SO-CTRL-TOTAL-MATCH = "Y" AND
              TXSM-SO-AMOUNT-SUM = 300
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " ctrl total match"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-SO-STATUS
                        " sum=" TXSM-SO-AMOUNT-SUM
                        " match=" TXSM-SO-CTRL-TOTAL-MATCH
           END-IF.

       TC06-SORT-CTRL-WARN.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE-VALID
           MOVE 5 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEFAULT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-T-COUNT
           MOVE 1000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-SORT
           IF TXSM-SO-STATUS = "04" AND
              TXSM-SO-CTRL-TOTAL-MATCH = "N"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " ctrl warn"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-SO-STATUS
                        " match=" TXSM-SO-CTRL-TOTAL-MATCH
           END-IF.

       TC07-SORT-MISSING-INPUT.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           CALL "SYSTEM" USING "rm -f /tmp/txsm-test/txn-valid.dat"
           PERFORM CALL-SORT
           IF TXSM-SO-STATUS = "12"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " missing input → IO-FAIL"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-SO-STATUS
           END-IF.

       TC08-SORT-LOSSLESS-VERIFY.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM OPEN-FIXTURE-VALID
           MOVE 5 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEFAULT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 2 TO BLD-D-SEQ
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 3 TO BLD-D-SEQ
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 4 TO BLD-D-SEQ
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 5 TO BLD-D-SEQ
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 5 TO BLD-T-COUNT
           MOVE 5000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-SORT
           IF TXSM-SO-STATUS = "00" AND
              TXSM-SO-RECORDS-PROCESSED = TXSM-SO-RECORDS-SORTED AND
              TXSM-SO-RECORDS-SORTED = 5
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " lossless 5 D"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " in=" TXSM-SO-RECORDS-PROCESSED
                        " out=" TXSM-SO-RECORDS-SORTED
           END-IF.

       SETUP-SORTED-3-D.
           PERFORM CLEANUP-TEST-FILES
           PERFORM OPEN-FIXTURE-VALID
           MOVE 3 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 1 TO BLD-D-SEQ
           MOVE "0010010000001" TO BLD-D-PAYER
           MOVE 100 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-D-SEQ
           MOVE "0010010000002" TO BLD-D-PAYER
           MOVE 200 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-D-SEQ
           MOVE "0010010000003" TO BLD-D-PAYER
           MOVE 300 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 3 TO BLD-T-COUNT
           MOVE 600 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-SORT.

       TC09-MERGE-EMPTY-RECON.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM SETUP-SORTED-3-D
           PERFORM CALL-MERGE
           IF TXSM-MO-STATUS = "00" AND
              TXSM-MO-RECORDS-SORTED-IN = 3 AND
              TXSM-MO-RECORDS-RECON-IN = 0 AND
              TXSM-MO-RECORDS-MERGED-OUT = 3 AND
              TXSM-MO-RECON-PRESENT-FLAG = "N"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " merge empty recon"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-MO-STATUS
                        " in=" TXSM-MO-RECORDS-SORTED-IN
                        " out=" TXSM-MO-RECORDS-MERGED-OUT
                        " recon=" TXSM-MO-RECON-PRESENT-FLAG
           END-IF.

       TC10-MERGE-DISJOINT-RECON.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM SETUP-SORTED-3-D
           PERFORM OPEN-FIXTURE-RECON
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 1 TO BLD-D-SEQ
           MOVE "0010010000005" TO BLD-D-PAYER
           MOVE 50 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-D-SEQ
           MOVE "0010010000006" TO BLD-D-PAYER
           MOVE 75 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-MERGE
           IF TXSM-MO-STATUS = "00" AND
              TXSM-MO-RECORDS-SORTED-IN = 3 AND
              TXSM-MO-RECORDS-RECON-IN = 2 AND
              TXSM-MO-RECORDS-MERGED-OUT = 5 AND
              TXSM-MO-DUPLICATE-RECORDS = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " merge disjoint 3+2=5"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-MO-STATUS
                        " in=" TXSM-MO-RECORDS-SORTED-IN
                        " recon=" TXSM-MO-RECORDS-RECON-IN
                        " out=" TXSM-MO-RECORDS-MERGED-OUT
                        " dup=" TXSM-MO-DUPLICATE-RECORDS
           END-IF.

       TC11-MERGE-INTERLEAVED.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM CLEANUP-TEST-FILES
           PERFORM OPEN-FIXTURE-VALID
           MOVE 3 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 1 TO BLD-D-SEQ
           MOVE "0010010000001" TO BLD-D-PAYER
           PERFORM WRITE-DETAIL-CURRENT
           MOVE "0010010000003" TO BLD-D-PAYER
           PERFORM WRITE-DETAIL-CURRENT
           MOVE "0010010000005" TO BLD-D-PAYER
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 3 TO BLD-T-COUNT
           MOVE 3000 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-SORT
           PERFORM OPEN-FIXTURE-RECON
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 1 TO BLD-D-SEQ
           MOVE "0010010000002" TO BLD-D-PAYER
           PERFORM WRITE-DETAIL-CURRENT
           MOVE "0010010000004" TO BLD-D-PAYER
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-MERGE
           IF TXSM-MO-STATUS = "00" AND
              TXSM-MO-RECORDS-MERGED-OUT = 5
               PERFORM VERIFY-INTERLEAVED-ORDER
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-MO-STATUS
                        " out=" TXSM-MO-RECORDS-MERGED-OUT
           END-IF.

       VERIFY-INTERLEAVED-ORDER.
           MOVE WS-READY-P TO WS-VER-PATH
           OPEN INPUT VERIFY-IN-FILE
           READ VERIFY-IN-FILE INTO VER-REC AT END CONTINUE END-READ
           READ VERIFY-IN-FILE INTO WS-VERIFY-D AT END CONTINUE END-READ
           IF WV-PAYER NOT = "0010010000001"
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " 1st=" WV-PAYER
               CLOSE VERIFY-IN-FILE
               EXIT PARAGRAPH
           END-IF
           READ VERIFY-IN-FILE INTO WS-VERIFY-D AT END CONTINUE END-READ
           IF WV-PAYER NOT = "0010010000002"
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " 2nd=" WV-PAYER
               CLOSE VERIFY-IN-FILE
               EXIT PARAGRAPH
           END-IF
           READ VERIFY-IN-FILE INTO WS-VERIFY-D AT END CONTINUE END-READ
           IF WV-PAYER NOT = "0010010000003"
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " 3rd=" WV-PAYER
               CLOSE VERIFY-IN-FILE
               EXIT PARAGRAPH
           END-IF
           CLOSE VERIFY-IN-FILE
           ADD 1 TO WS-P
           DISPLAY "  [PASS] " WS-TC-NUM " merge interleave 1-5".

       TC12-MERGE-DUPLICATE-E050.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM SETUP-SORTED-3-D
           PERFORM OPEN-FIXTURE-RECON
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 1 TO BLD-D-SEQ
           MOVE "0010010000001" TO BLD-D-PAYER
           MOVE 999 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-MERGE
           IF TXSM-MO-STATUS = "04" AND
              TXSM-MO-DUPLICATE-RECORDS = 2 AND
              TXSM-MO-DUPLICATE-PAIRS = 1 AND
              TXSM-MO-RECORDS-MERGED-OUT = 2
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " duplicate E050"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-MO-STATUS
                        " out=" TXSM-MO-RECORDS-MERGED-OUT
                        " dup=" TXSM-MO-DUPLICATE-RECORDS
                        " pairs=" TXSM-MO-DUPLICATE-PAIRS
           END-IF.

       TC13-MERGE-RECON-VIOLATION.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM SETUP-SORTED-3-D
           PERFORM OPEN-FIXTURE-RECON
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 1 TO BLD-D-SEQ
           MOVE "0010010000005" TO BLD-D-PAYER
           PERFORM WRITE-DETAIL-CURRENT
           MOVE 1 TO BLD-D-SEQ
           MOVE "0010010000001" TO BLD-D-PAYER
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-MERGE
           IF TXSM-MO-STATUS = "08" AND
              TXSM-MO-SORT-VIOLATIONS >= 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " recon sort violation"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-MO-STATUS
                        " viol=" TXSM-MO-SORT-VIOLATIONS
           END-IF.

       TC14-MERGE-ALL-RECON-NO-SORTED.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM CLEANUP-TEST-FILES
           PERFORM OPEN-FIXTURE-VALID
           MOVE 0 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           MOVE 0 TO BLD-T-COUNT
           MOVE 0 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-SORT
           PERFORM OPEN-FIXTURE-RECON
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 1 TO BLD-D-SEQ
           MOVE "0010010000001" TO BLD-D-PAYER
           MOVE 100 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           MOVE "0010010000002" TO BLD-D-PAYER
           MOVE 200 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-MERGE
           IF TXSM-MO-STATUS = "00" AND
              TXSM-MO-RECORDS-SORTED-IN = 0 AND
              TXSM-MO-RECORDS-RECON-IN = 2 AND
              TXSM-MO-RECORDS-MERGED-OUT = 2
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " all recon no sorted"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-MO-STATUS
                        " in=" TXSM-MO-RECORDS-SORTED-IN
                        " recon=" TXSM-MO-RECORDS-RECON-IN
                        " out=" TXSM-MO-RECORDS-MERGED-OUT
           END-IF.

       TC15-MERGE-ALL-SORTED-NO-RECON.
           PERFORM TC09-MERGE-EMPTY-RECON.

       TC16-MERGE-CONSERVATION-OK.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM SETUP-SORTED-3-D
           PERFORM OPEN-FIXTURE-RECON
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 1 TO BLD-D-SEQ
           MOVE "0010010000007" TO BLD-D-PAYER
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-MERGE
           IF TXSM-MO-STATUS = "00" AND
              (TXSM-MO-RECORDS-SORTED-IN +
               TXSM-MO-RECORDS-RECON-IN) =
              (TXSM-MO-RECORDS-MERGED-OUT +
               TXSM-MO-DUPLICATE-RECORDS)
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " conservation invariant"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " in+recon=" TXSM-MO-RECORDS-SORTED-IN
                        "+" TXSM-MO-RECORDS-RECON-IN
                        " out+dup=" TXSM-MO-RECORDS-MERGED-OUT
                        "+" TXSM-MO-DUPLICATE-RECORDS
           END-IF.

       TC17-MERGE-BOTH-EMPTY.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM CLEANUP-TEST-FILES
           PERFORM OPEN-FIXTURE-VALID
           MOVE 0 TO BLD-H-EXPECTED
           PERFORM WRITE-HEADER-DEFAULT
           MOVE 0 TO BLD-T-COUNT
           MOVE 0 TO BLD-T-AMTSUM
           PERFORM WRITE-TRAILER-CNT-AMT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-SORT
           PERFORM CALL-MERGE
           IF TXSM-MO-STATUS = "00" AND
              TXSM-MO-RECORDS-SORTED-IN = 0 AND
              TXSM-MO-RECORDS-RECON-IN = 0 AND
              TXSM-MO-RECORDS-MERGED-OUT = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " both empty"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-MO-STATUS
                        " out=" TXSM-MO-RECORDS-MERGED-OUT
           END-IF.

       TC18-MERGE-HEADER-COMBINE.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM SETUP-SORTED-3-D
           PERFORM OPEN-FIXTURE-RECON
           PERFORM INIT-DETAIL-DEFAULT
           MOVE 1 TO BLD-D-SEQ
           MOVE "0010010000010" TO BLD-D-PAYER
           MOVE 400 TO BLD-D-AMOUNT
           PERFORM WRITE-DETAIL-CURRENT
           PERFORM CLOSE-FIXTURE
           PERFORM CALL-MERGE
           IF TXSM-MO-STATUS = "00" AND
              TXSM-MO-AMOUNT-SUM = 1000
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " amount combine 1000"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-MO-STATUS
                        " sum=" TXSM-MO-AMOUNT-SUM
           END-IF.

       TC19-REPORT-BOTH-PHASES.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM CLEANUP-REPORT-FILES
           PERFORM WRITE-SUMMARY-BOTH-LINES
           MOVE "BATCH-11-TEST01"  TO TXSM-RP-BATCH-ID
           MOVE WS-SUM-P           TO TXSM-RP-SUMMARY-FILENAME
           MOVE WS-RPT-P           TO TXSM-RP-REPORT-FILENAME
           CALL "TXSM-REPORT-SUMMARY"
                USING TXSM-REPORT-INPUT TXSM-REPORT-OUTPUT
           IF TXSM-RP-STATUS = "00" AND
              TXSM-RP-LINES-WRITTEN > 5
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " report both phases"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-RP-STATUS
                        " lines=" TXSM-RP-LINES-WRITTEN
           END-IF.

       TC20-REPORT-SORT-ONLY.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM CLEANUP-REPORT-FILES
           PERFORM WRITE-SUMMARY-SORT-LINE
           MOVE "BATCH-11-TEST01"  TO TXSM-RP-BATCH-ID
           MOVE WS-SUM-P           TO TXSM-RP-SUMMARY-FILENAME
           MOVE WS-RPT-P           TO TXSM-RP-REPORT-FILENAME
           CALL "TXSM-REPORT-SUMMARY"
                USING TXSM-REPORT-INPUT TXSM-REPORT-OUTPUT
           IF TXSM-RP-STATUS = "04" OR TXSM-RP-STATUS = "00"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " report sort only"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-RP-STATUS
           END-IF.

       TC21-REPORT-EMPTY-SUMMARY.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM CLEANUP-REPORT-FILES
           PERFORM WRITE-SUMMARY-EMPTY
           MOVE "BATCH-11-TEST01"  TO TXSM-RP-BATCH-ID
           MOVE WS-SUM-P           TO TXSM-RP-SUMMARY-FILENAME
           MOVE WS-RPT-P           TO TXSM-RP-REPORT-FILENAME
           CALL "TXSM-REPORT-SUMMARY"
                USING TXSM-REPORT-INPUT TXSM-REPORT-OUTPUT
           IF TXSM-RP-STATUS = "04" OR TXSM-RP-STATUS = "00"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " report empty summary"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-RP-STATUS
           END-IF.

       TC22-REPORT-CONSERVATION-VERIFY.
           ADD 1 TO WS-N MOVE WS-N TO WS-TC-NUM
           PERFORM CLEANUP-REPORT-FILES
           PERFORM WRITE-SUMMARY-BOTH-WITH-DUP
           MOVE "BATCH-11-TEST01"  TO TXSM-RP-BATCH-ID
           MOVE WS-SUM-P           TO TXSM-RP-SUMMARY-FILENAME
           MOVE WS-RPT-P           TO TXSM-RP-REPORT-FILENAME
           CALL "TXSM-REPORT-SUMMARY"
                USING TXSM-REPORT-INPUT TXSM-REPORT-OUTPUT
           IF TXSM-RP-STATUS = "00" AND
              TXSM-RP-CONSERVATION-OK = "Y"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " conservation Y"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-TC-NUM
                        " st=" TXSM-RP-STATUS
                        " conv=" TXSM-RP-CONSERVATION-OK
           END-IF.

       END PROGRAM TXSM-TEST.
