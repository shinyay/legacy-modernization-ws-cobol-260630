       IDENTIFICATION DIVISION.
       PROGRAM-ID. DEH-TEST.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  WS-N           PIC 9(3) VALUE 0.
       01  WS-P           PIC 9(3) VALUE 0.
       01  WS-F           PIC 9(3) VALUE 0.
       01  WS-TC-NUM      PIC 9(3).

           COPY "double-entry-helper.cpy".

       01  WS-CASH-ACCT       PIC X(13) VALUE "0010010000001".
       01  WS-CLEARING-ACCT   PIC X(13) VALUE "0010010000002".
       01  WS-INT-EXPENSE     PIC X(13) VALUE "0010010000003".
       01  WS-FEE-REVENUE     PIC X(13) VALUE "0010010000004".
       01  WS-CUST-ACCT       PIC X(13) VALUE "0010010099001".
       01  WS-CUST-ACCT-2     PIC X(13) VALUE "0010010099002".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== double-entry-helper unit tests (Phase 5 Step 0) ==="
           PERFORM TC01-CAT10-DEPOSIT-VALID
           PERFORM TC02-CAT20-WITHDRAW-VALID
           PERFORM TC03-CAT30-TRANSFER-VALID-POS
           PERFORM TC04-CAT40-WIRE-VALID
           PERFORM TC05-CAT50-INTEREST-VALID
           PERFORM TC06-CAT60-FEE-VALID
           PERFORM TC07-CAT99-INVALID
           PERFORM TC08-CAT00-INVALID
           PERFORM TC09-DR-BLANK
           PERFORM TC10-CR-BLANK
           PERFORM TC11-CAT10-NEG-AMOUNT
           PERFORM TC12-CAT20-POS-AMOUNT
           PERFORM TC13-CAT30-ZERO-AMOUNT
           PERFORM TC14-CAT40-POS-AMOUNT
           PERFORM TC15-CAT50-NEG-AMOUNT
           PERFORM TC16-CAT60-POS-AMOUNT
           PERFORM TC17-REALISTIC-14-IPST
           PERFORM TC18-REALISTIC-15-ADBT
           PERFORM TC19-REALISTIC-16-FEE
           PERFORM TC20-MAX-AMOUNT-EDGE
           DISPLAY "=== Total: " WS-N
                   " | PASS: " WS-P
                   " | FAIL: " WS-F
           IF WS-F > 0
               STOP RUN RETURNING 1
           END-IF
           STOP RUN.

       RESET-INPUTS.
           MOVE 0 TO DEH-CAT
           MOVE 0 TO DEH-AMOUNT-JPY
           MOVE SPACES TO DEH-DR-ACCT DEH-CR-ACCT
           MOVE 0 TO DEH-RC
           MOVE SPACES TO DEH-MSG.

       TC01-CAT10-DEPOSIT-VALID.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 10 TO DEH-CAT
           MOVE 1000 TO DEH-AMOUNT-JPY
           MOVE WS-CASH-ACCT TO DEH-DR-ACCT
           MOVE WS-CUST-ACCT TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat10 deposit valid"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC02-CAT20-WITHDRAW-VALID.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 20 TO DEH-CAT
           MOVE -1000 TO DEH-AMOUNT-JPY
           MOVE WS-CUST-ACCT TO DEH-DR-ACCT
           MOVE WS-CASH-ACCT TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat20 withdraw valid"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC03-CAT30-TRANSFER-VALID-POS.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 30 TO DEH-CAT
           MOVE 500 TO DEH-AMOUNT-JPY
           MOVE WS-CUST-ACCT TO DEH-DR-ACCT
           MOVE WS-CUST-ACCT-2 TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat30 transfer valid"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC04-CAT40-WIRE-VALID.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 40 TO DEH-CAT
           MOVE -1000 TO DEH-AMOUNT-JPY
           MOVE WS-CUST-ACCT TO DEH-DR-ACCT
           MOVE WS-CLEARING-ACCT TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat40 wire valid"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC05-CAT50-INTEREST-VALID.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 50 TO DEH-CAT
           MOVE 100 TO DEH-AMOUNT-JPY
           MOVE WS-INT-EXPENSE TO DEH-DR-ACCT
           MOVE WS-CUST-ACCT TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat50 interest valid"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC06-CAT60-FEE-VALID.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 60 TO DEH-CAT
           MOVE -500 TO DEH-AMOUNT-JPY
           MOVE WS-CUST-ACCT TO DEH-DR-ACCT
           MOVE WS-FEE-REVENUE TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat60 fee valid"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC07-CAT99-INVALID.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 99 TO DEH-CAT
           MOVE 1000 TO DEH-AMOUNT-JPY
           MOVE WS-CASH-ACCT TO DEH-DR-ACCT
           MOVE WS-CUST-ACCT TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 30
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat99 invalid rc=30"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC08-CAT00-INVALID.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 0 TO DEH-CAT
           MOVE 1000 TO DEH-AMOUNT-JPY
           MOVE WS-CASH-ACCT TO DEH-DR-ACCT
           MOVE WS-CUST-ACCT TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 30
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat00 invalid rc=30"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC09-DR-BLANK.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 10 TO DEH-CAT
           MOVE 1000 TO DEH-AMOUNT-JPY
           MOVE SPACES TO DEH-DR-ACCT
           MOVE WS-CUST-ACCT TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 40
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " DR blank rc=40"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC10-CR-BLANK.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 10 TO DEH-CAT
           MOVE 1000 TO DEH-AMOUNT-JPY
           MOVE WS-CASH-ACCT TO DEH-DR-ACCT
           MOVE SPACES TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 40
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " CR blank rc=40"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC11-CAT10-NEG-AMOUNT.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 10 TO DEH-CAT
           MOVE -1000 TO DEH-AMOUNT-JPY
           MOVE WS-CASH-ACCT TO DEH-DR-ACCT
           MOVE WS-CUST-ACCT TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 20
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat10 sign mismatch rc=20"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC12-CAT20-POS-AMOUNT.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 20 TO DEH-CAT
           MOVE 1000 TO DEH-AMOUNT-JPY
           MOVE WS-CUST-ACCT TO DEH-DR-ACCT
           MOVE WS-CASH-ACCT TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 20
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat20 sign mismatch rc=20"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC13-CAT30-ZERO-AMOUNT.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 30 TO DEH-CAT
           MOVE 0 TO DEH-AMOUNT-JPY
           MOVE WS-CUST-ACCT TO DEH-DR-ACCT
           MOVE WS-CUST-ACCT-2 TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 20
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat30 zero rc=20"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC14-CAT40-POS-AMOUNT.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 40 TO DEH-CAT
           MOVE 1000 TO DEH-AMOUNT-JPY
           MOVE WS-CUST-ACCT TO DEH-DR-ACCT
           MOVE WS-CLEARING-ACCT TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 20
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat40 sign mismatch rc=20"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC15-CAT50-NEG-AMOUNT.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 50 TO DEH-CAT
           MOVE -100 TO DEH-AMOUNT-JPY
           MOVE WS-INT-EXPENSE TO DEH-DR-ACCT
           MOVE WS-CUST-ACCT TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 20
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat50 sign mismatch rc=20"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC16-CAT60-POS-AMOUNT.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 60 TO DEH-CAT
           MOVE 500 TO DEH-AMOUNT-JPY
           MOVE WS-CUST-ACCT TO DEH-DR-ACCT
           MOVE WS-FEE-REVENUE TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 20
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " cat60 sign mismatch rc=20"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC17-REALISTIC-14-IPST.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 50 TO DEH-CAT
           MOVE 250 TO DEH-AMOUNT-JPY
           MOVE WS-INT-EXPENSE TO DEH-DR-ACCT
           MOVE WS-CUST-ACCT TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " realistic 14-IPST rc=00"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC18-REALISTIC-15-ADBT.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 20 TO DEH-CAT
           MOVE -5000 TO DEH-AMOUNT-JPY
           MOVE WS-CUST-ACCT TO DEH-DR-ACCT
           MOVE WS-CASH-ACCT TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " realistic 15-ADBT rc=00"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC19-REALISTIC-16-FEE.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 60 TO DEH-CAT
           MOVE -150 TO DEH-AMOUNT-JPY
           MOVE WS-CUST-ACCT TO DEH-DR-ACCT
           MOVE WS-FEE-REVENUE TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " realistic 16-FEE rc=00"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

       TC20-MAX-AMOUNT-EDGE.
           ADD 1 TO WS-N
           MOVE WS-N TO WS-TC-NUM
           PERFORM RESET-INPUTS
           MOVE 10 TO DEH-CAT
           MOVE 999999999999999 TO DEH-AMOUNT-JPY
           MOVE WS-CASH-ACCT TO DEH-DR-ACCT
           MOVE WS-CUST-ACCT TO DEH-CR-ACCT
           PERFORM DEH-VALIDATE
           IF DEH-RC = 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-TC-NUM " max amount edge rc=00"
           ELSE
               ADD 1 TO WS-F
               DISPLAY "  [FAIL] " WS-TC-NUM " rc=" DEH-RC " msg=" DEH-MSG
           END-IF.

           COPY "double-entry-helper-procs.cpy".

       END PROGRAM DEH-TEST.
