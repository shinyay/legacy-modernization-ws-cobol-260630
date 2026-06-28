       IDENTIFICATION DIVISION.
       PROGRAM-ID. E2E-CONC-GEN.
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
       01  WS-BATCH-ID              PIC X(14) VALUE "E2E-CONC-001".
       01  WS-BDATE                 PIC 9(8) VALUE 20260612.
       01  WS-COUNT                 PIC 9(8) VALUE 30.
       01  WS-CAT                   PIC X(2) VALUE "10".
       01  WS-PAYER                 PIC X(13) VALUE "0010010099001".
       01  WS-PAYEE                 PIC X(13) VALUE SPACES.
       01  WS-AMOUNT                PIC 9(15) VALUE 1000.
       01  WS-SEQ0                  PIC 9(10) VALUE 1.
       01  WS-I                     PIC 9(10).
       01  WS-CUR-SEQ               PIC 9(10).
       01  WS-AMOUNT-SUM            PIC 9(20) VALUE 0.

       01  WS-HEADER.
           05  H-TYPE               PIC X(1) VALUE "H".
           05  H-BATCH              PIC X(14).
           05  H-BDATE              PIC 9(8).
           05  H-SRC                PIC X(20) VALUE "E2E_CONC".
           05  H-EXPECTED           PIC 9(10).
           05  H-CHKSUM             PIC X(40) VALUE
                                  "0000000000000000000000000000000000000000".
           05  H-FILLER             PIC X(507) VALUE SPACES.

       01  WS-DETAIL.
           05  D-TYPE               PIC X(1) VALUE "D".
           05  D-SEQ                PIC 9(10) VALUE 0.
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
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-COUNT
               COMPUTE WS-CUR-SEQ = WS-SEQ0 + WS-I - 1
               PERFORM EMIT-DETAIL
           END-PERFORM
           PERFORM WRITE-TRAILER
           CLOSE OUT-FILE
           DISPLAY "[e2e-conc-gen] batch=" WS-BATCH-ID
                   " cat=" WS-CAT
                   " count=" WS-COUNT
                   " payer=" WS-PAYER
                   " payee=" WS-PAYEE
                   " sum=" WS-AMOUNT-SUM
           STOP RUN.

       READ-ENV.
           MOVE SPACES TO WS-OUTPUT-PATH
           ACCEPT WS-ENV-VAL FROM ENVIRONMENT 'E2E_CONC_PATH'
           IF WS-ENV-VAL NOT = SPACES
               MOVE WS-ENV-VAL TO WS-OUTPUT-PATH
           ELSE
               MOVE "/tmp/e2e/conc-ready.dat" TO WS-OUTPUT-PATH
           END-IF
           ACCEPT WS-ENV-VAL FROM ENVIRONMENT 'E2E_BATCH_ID'
           IF WS-ENV-VAL NOT = SPACES
               MOVE WS-ENV-VAL(1:14) TO WS-BATCH-ID
           END-IF
           ACCEPT WS-ENV-VAL FROM ENVIRONMENT 'E2E_BDATE'
           IF WS-ENV-VAL NOT = SPACES
               COMPUTE WS-BDATE = FUNCTION NUMVAL(WS-ENV-VAL)
           END-IF
           ACCEPT WS-ENV-VAL FROM ENVIRONMENT 'E2E_CONC_COUNT'
           IF WS-ENV-VAL NOT = SPACES
               COMPUTE WS-COUNT = FUNCTION NUMVAL(WS-ENV-VAL)
           END-IF
           ACCEPT WS-ENV-VAL FROM ENVIRONMENT 'E2E_CONC_CAT'
           IF WS-ENV-VAL NOT = SPACES
               MOVE WS-ENV-VAL(1:2) TO WS-CAT
           END-IF
           ACCEPT WS-ENV-VAL FROM ENVIRONMENT 'E2E_CONC_PAYER'
           IF WS-ENV-VAL NOT = SPACES
               MOVE WS-ENV-VAL(1:13) TO WS-PAYER
           END-IF
           MOVE SPACES TO WS-PAYEE
           ACCEPT WS-ENV-VAL FROM ENVIRONMENT 'E2E_CONC_PAYEE'
           IF WS-ENV-VAL NOT = SPACES
               MOVE WS-ENV-VAL(1:13) TO WS-PAYEE
           END-IF
           ACCEPT WS-ENV-VAL FROM ENVIRONMENT 'E2E_CONC_AMOUNT'
           IF WS-ENV-VAL NOT = SPACES
               COMPUTE WS-AMOUNT = FUNCTION NUMVAL(WS-ENV-VAL)
           END-IF
           ACCEPT WS-ENV-VAL FROM ENVIRONMENT 'E2E_CONC_SEQ0'
           IF WS-ENV-VAL NOT = SPACES
               COMPUTE WS-SEQ0 = FUNCTION NUMVAL(WS-ENV-VAL)
           END-IF.

       OPEN-OUTPUT.
           OPEN OUTPUT OUT-FILE
           IF WS-FS NOT = "00"
               DISPLAY "[e2e-conc-gen] OPEN failed fs=" WS-FS
                       " path=" FUNCTION TRIM(WS-OUTPUT-PATH)
                       UPON SYSERR
               STOP RUN RETURNING 12
           END-IF.

       WRITE-HEADER.
           MOVE WS-BATCH-ID TO H-BATCH
           MOVE WS-BDATE    TO H-BDATE
           MOVE WS-COUNT    TO H-EXPECTED
           WRITE OUT-REC FROM WS-HEADER.

       EMIT-DETAIL.
           MOVE WS-CUR-SEQ TO D-SEQ
           MOVE WS-CUR-SEQ TO D-ORIG-SEQ
           MOVE WS-CAT     TO D-CAT
           MOVE WS-AMOUNT  TO D-AMOUNT
           MOVE "JPY"      TO D-CCY
           MOVE WS-PAYER   TO D-PAYER
           MOVE WS-PAYEE   TO D-PAYEE
           MOVE 001        TO D-BRANCH
           MOVE 001        TO D-PRODUCT
           ADD WS-AMOUNT TO WS-AMOUNT-SUM
           WRITE OUT-REC FROM WS-DETAIL.

       WRITE-TRAILER.
           MOVE WS-COUNT      TO T-COUNT
           MOVE WS-AMOUNT-SUM TO T-AMTSUM
           WRITE OUT-REC FROM WS-TRAILER.

       END PROGRAM E2E-CONC-GEN.
