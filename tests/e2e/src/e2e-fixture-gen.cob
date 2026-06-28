       IDENTIFICATION DIVISION.
       PROGRAM-ID. E2E-FIXTURE-GEN.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT OUT-FILE
               ASSIGN TO WS-OUTPUT-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS.

       DATA DIVISION.
       FILE SECTION.
       FD  OUT-FILE.
       01  OUT-REC                  PIC X(600).

       WORKING-STORAGE SECTION.
       01  WS-FS                    PIC X(2).
       01  WS-OUTPUT-PATH           PIC X(120).
       01  WS-ENV-VAL               PIC X(120).
       01  WS-TOTAL                 PIC 9(8) VALUE 100.
       01  WS-VALID-RATIO           PIC 9(3) VALUE 90.
       01  WS-BATCH-ID              PIC X(14) VALUE "BATCH-E2E-0001".
       01  WS-BDATE                 PIC 9(8) VALUE 20260612.
       01  WS-I                     PIC 9(8) VALUE 1.
       01  WS-VALID-CNT             PIC 9(8) VALUE 0.
       01  WS-ERROR-CNT             PIC 9(8) VALUE 0.
       01  WS-AMOUNT-SUM            PIC 9(20) VALUE 0.
       01  WS-MOD-3                 PIC 9(1).
       01  WS-MOD-10                PIC 9(2).
       01  WS-ACCT                  PIC X(13).

       01  WS-HEADER.
           05  H-TYPE               PIC X(1) VALUE "H".
           05  H-BATCH              PIC X(14).
           05  H-BDATE              PIC 9(8).
           05  H-SRC                PIC X(20) VALUE "E2E_BATCH".
           05  H-EXPECTED           PIC 9(10).
           05  H-CHKSUM             PIC X(40) VALUE
                                  "0000000000000000000000000000000000000000".
           05  H-FILLER             PIC X(507) VALUE SPACES.

       01  WS-DETAIL.
           05  D-TYPE               PIC X(1) VALUE "D".
           05  D-SEQ                PIC 9(10) VALUE 1.
           05  D-CAT                PIC X(2) VALUE "10".
           05  D-AMOUNT             PIC 9(15) VALUE 1000.
           05  D-CCY                PIC X(3) VALUE "JPY".
           05  D-PAYER              PIC X(13) VALUE "0010010099001".
           05  D-PAYEE              PIC X(13) VALUE SPACES.
           05  D-BRANCH             PIC 9(3) VALUE 001.
           05  D-PRODUCT            PIC 9(3) VALUE 001.
           05  D-DESC               PIC X(120) VALUE SPACES.
           05  D-SRC-BANK           PIC X(4)  VALUE SPACES.
           05  D-SRC-BRANCH         PIC X(3)  VALUE SPACES.
           05  D-ORIG-SEQ           PIC 9(10) VALUE 0.
           05  D-FILLER             PIC X(400) VALUE SPACES.

       01  WS-TRAILER.
           05  T-TYPE               PIC X(1) VALUE "T".
           05  T-COUNT              PIC 9(10).
           05  T-AMTSUM             PIC 9(20).
           05  T-CHKSUM             PIC X(40) VALUE
                                  "0000000000000000000000000000000000000000".
           05  T-FILLER             PIC X(529) VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           PERFORM READ-ENV
           PERFORM OPEN-OUTPUT
           PERFORM WRITE-HEADER
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-TOTAL
               PERFORM WRITE-ONE-DETAIL
           END-PERFORM
           PERFORM WRITE-TRAILER
           CLOSE OUT-FILE
           DISPLAY "[e2e-fixture-gen] total=" WS-TOTAL
                   " valid=" WS-VALID-CNT
                   " err="   WS-ERROR-CNT
                   " sum="   WS-AMOUNT-SUM
                   " out="   FUNCTION TRIM(WS-OUTPUT-PATH)
           STOP RUN.

       READ-ENV.
           ACCEPT WS-ENV-VAL FROM ENVIRONMENT 'E2E_TOTAL'
           IF WS-ENV-VAL NOT = SPACES
               COMPUTE WS-TOTAL = FUNCTION NUMVAL(WS-ENV-VAL)
           END-IF
           ACCEPT WS-ENV-VAL FROM ENVIRONMENT 'E2E_VALID_RATIO'
           IF WS-ENV-VAL NOT = SPACES
               COMPUTE WS-VALID-RATIO = FUNCTION NUMVAL(WS-ENV-VAL)
           END-IF
           MOVE SPACES TO WS-OUTPUT-PATH
           ACCEPT WS-ENV-VAL FROM ENVIRONMENT 'E2E_OUTPUT'
           IF WS-ENV-VAL NOT = SPACES
               MOVE WS-ENV-VAL TO WS-OUTPUT-PATH
           ELSE
               MOVE "/tmp/e2e/txn-decoded.dat" TO WS-OUTPUT-PATH
           END-IF
           ACCEPT WS-ENV-VAL FROM ENVIRONMENT 'E2E_BATCH_ID'
           IF WS-ENV-VAL NOT = SPACES
               MOVE WS-ENV-VAL(1:14) TO WS-BATCH-ID
           END-IF
           ACCEPT WS-ENV-VAL FROM ENVIRONMENT 'E2E_BDATE'
           IF WS-ENV-VAL NOT = SPACES
               COMPUTE WS-BDATE = FUNCTION NUMVAL(WS-ENV-VAL)
           END-IF.

       OPEN-OUTPUT.
           OPEN OUTPUT OUT-FILE
           IF WS-FS NOT = "00"
               DISPLAY "[e2e-fixture-gen] OPEN failed fs=" WS-FS
                       " path=" FUNCTION TRIM(WS-OUTPUT-PATH)
                       UPON SYSERR
               STOP RUN RETURNING 12
           END-IF.

       WRITE-HEADER.
           MOVE WS-BATCH-ID TO H-BATCH
           MOVE WS-BDATE    TO H-BDATE
           MOVE WS-TOTAL    TO H-EXPECTED
           WRITE OUT-REC FROM WS-HEADER.

       WRITE-ONE-DETAIL.
           MOVE WS-I        TO D-SEQ
           MOVE "10"        TO D-CAT
           MOVE 1000        TO D-AMOUNT
           MOVE "JPY"       TO D-CCY
           MOVE SPACES      TO D-PAYEE
           MOVE 001         TO D-BRANCH
           MOVE 001         TO D-PRODUCT
           MOVE SPACES      TO D-DESC
           MOVE SPACES      TO D-SRC-BANK
           MOVE SPACES      TO D-SRC-BRANCH
           MOVE WS-I        TO D-ORIG-SEQ
           COMPUTE WS-MOD-3 = FUNCTION MOD(WS-I, 3)
           EVALUATE WS-MOD-3
               WHEN 0 MOVE "0010010099001" TO D-PAYER
               WHEN 1 MOVE "0010010099002" TO D-PAYER
               WHEN 2 MOVE "0010010099003" TO D-PAYER
           END-EVALUATE
           IF WS-VALID-RATIO < 100
               COMPUTE WS-MOD-10 = FUNCTION MOD(WS-I, 10)
               IF WS-MOD-10 = 5
                   COMPUTE WS-MOD-3 = FUNCTION MOD(WS-I / 10, 5)
                   EVALUATE WS-MOD-3
                       WHEN 0
                           MOVE "99" TO D-CAT
                       WHEN 1
                           MOVE 0    TO D-AMOUNT
                       WHEN 2
                           MOVE 999  TO D-BRANCH
                       WHEN 3
                           MOVE 999  TO D-PRODUCT
                       WHEN 4
                           MOVE "30" TO D-CAT
                           MOVE SPACES TO D-PAYEE
                   END-EVALUATE
                   ADD 1 TO WS-ERROR-CNT
               ELSE
                   ADD 1 TO WS-VALID-CNT
               END-IF
           ELSE
               ADD 1 TO WS-VALID-CNT
           END-IF
           ADD D-AMOUNT TO WS-AMOUNT-SUM
           WRITE OUT-REC FROM WS-DETAIL.

       WRITE-TRAILER.
           MOVE WS-TOTAL     TO T-COUNT
           MOVE WS-AMOUNT-SUM TO T-AMTSUM
           WRITE OUT-REC FROM WS-TRAILER.

       END PROGRAM E2E-FIXTURE-GEN.
