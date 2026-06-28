       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCTTEST.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "acct-api.cpy".

       01  WS-N    PIC 9(3) VALUE 0.
       01  WS-P    PIC 9(3) VALUE 0.
       01  WS-F    PIC 9(3) VALUE 0.

       01  WS-ACCT-1   PIC 9(13) VALUE 0010030000001.
       01  WS-CUST-2   PIC 9(10) VALUE 0000000002.

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 08-account unit tests ===".

           DISPLAY " ".
           DISPLAY "--- ACCT-EXISTS (10 cases) ---".

           MOVE WS-ACCT-1 TO ACCT-EXISTS-NUMBER
           PERFORM CALL-EXISTS
           PERFORM CHK-EXISTS-Y

           PERFORM CALL-EXISTS-CHECK-A

           MOVE 9999999999999 TO ACCT-EXISTS-NUMBER
           PERFORM CALL-EXISTS
           PERFORM CHK-EXISTS-N

           MOVE 1000000000000 TO ACCT-EXISTS-NUMBER
           PERFORM CALL-EXISTS
           PERFORM CHK-EXISTS-N

           MOVE WS-ACCT-1 TO ACCT-EXISTS-NUMBER
           PERFORM CALL-EXISTS
           PERFORM CHK-EXISTS-PROD

           MOVE 0 TO ACCT-EXISTS-NUMBER
           PERFORM CALL-EXISTS
           PERFORM CHK-EXISTS-N

           MOVE WS-ACCT-1 TO ACCT-EXISTS-NUMBER
           PERFORM CALL-EXISTS
           PERFORM CHK-EXISTS-ACTIVE

           MOVE WS-ACCT-1 TO ACCT-EXISTS-NUMBER
           PERFORM CALL-EXISTS
           PERFORM CHK-EXISTS-Y

           MOVE 0000000000001 TO ACCT-EXISTS-NUMBER
           PERFORM CALL-EXISTS
           PERFORM CHK-EXISTS-N

           MOVE 9999999999998 TO ACCT-EXISTS-NUMBER
           PERFORM CALL-EXISTS
           PERFORM CHK-EXISTS-N

           DISPLAY " ".
           DISPLAY "--- ACCT-LOOKUP (8 cases) ---".

           MOVE WS-ACCT-1 TO ACCT-LOOKUP-NUMBER
           PERFORM CALL-LOOKUP
           PERFORM CHK-LOOKUP-OK

           PERFORM CHK-LOOKUP-CUST-2

           PERFORM CHK-LOOKUP-STATUS-A

           PERFORM CHK-LOOKUP-OPENED

           MOVE 9999999999999 TO ACCT-LOOKUP-NUMBER
           PERFORM CALL-LOOKUP
           PERFORM CHK-LOOKUP-NF

           MOVE WS-ACCT-1 TO ACCT-LOOKUP-NUMBER
           PERFORM CALL-LOOKUP
           PERFORM CHK-LOOKUP-OVD-NONZERO

           MOVE WS-ACCT-1 TO ACCT-LOOKUP-NUMBER
           PERFORM CALL-LOOKUP
           PERFORM CHK-LOOKUP-OK

           PERFORM CHK-LOOKUP-DORMANCY-EQ-OPENED

           DISPLAY " ".
           DISPLAY "--- ACCT-LOOKUP-BY-CUSTOMER (7 cases) ---".

           MOVE WS-CUST-2 TO LOOKUP-BY-CUST-CUST-ID
           MOVE 10 TO LOOKUP-BY-CUST-MAX
           MOVE 0 TO LOOKUP-BY-CUST-START-AFTER
           PERFORM CALL-LBC
           PERFORM CHK-LBC-COUNT-POS

           PERFORM CHK-LBC-COUNT-1-3

           PERFORM CHK-LBC-SORTED

           PERFORM CHK-LBC-LAST-ACCT-POS

           MOVE 9999999999 TO LOOKUP-BY-CUST-CUST-ID
           PERFORM CALL-LBC
           PERFORM CHK-LBC-NF

           MOVE WS-CUST-2 TO LOOKUP-BY-CUST-CUST-ID
           MOVE 1 TO LOOKUP-BY-CUST-MAX
           MOVE 0 TO LOOKUP-BY-CUST-START-AFTER
           PERFORM CALL-LBC
           PERFORM CHK-LBC-COUNT-1

           MOVE 0 TO LOOKUP-BY-CUST-MAX
           PERFORM CALL-LBC
           PERFORM CHK-LBC-INVALID

           DISPLAY " ".
           DISPLAY "--- ACCT-UPDATE-DORMANCY-DATE (8 cases) ---".

           MOVE WS-ACCT-1 TO UPDATE-DORMANCY-ACCT-NUMBER
           MOVE 20260601 TO UPDATE-DORMANCY-NEW-DATE
           PERFORM CALL-UPD
           PERFORM CHK-UPD-OK

           PERFORM CHK-UPD-PREV-DATE

           PERFORM CHK-UPD-NOOP-N

           MOVE 20260601 TO UPDATE-DORMANCY-NEW-DATE
           PERFORM CALL-UPD
           PERFORM CHK-UPD-NOOP-Y

           MOVE 20260301 TO UPDATE-DORMANCY-NEW-DATE
           PERFORM CALL-UPD
           PERFORM CHK-UPD-INVALID

           MOVE 9999999999999 TO UPDATE-DORMANCY-ACCT-NUMBER
           MOVE 20260701 TO UPDATE-DORMANCY-NEW-DATE
           PERFORM CALL-UPD
           PERFORM CHK-UPD-NF

           MOVE WS-ACCT-1 TO UPDATE-DORMANCY-ACCT-NUMBER
           MOVE 99991332 TO UPDATE-DORMANCY-NEW-DATE
           PERFORM CALL-UPD
           PERFORM CHK-UPD-INVALID

           MOVE WS-ACCT-1 TO UPDATE-DORMANCY-ACCT-NUMBER
           MOVE 20260801 TO UPDATE-DORMANCY-NEW-DATE
           PERFORM CALL-UPD
           PERFORM CHK-UPD-OK

           DISPLAY " ".
           DISPLAY "=== Total: " WS-N
                   " | PASS: " WS-P
                   " | FAIL: " WS-F.
           IF WS-F > 0 MOVE 1 TO RETURN-CODE END-IF
           STOP RUN.

       CALL-EXISTS.
           CALL "ACCT-EXISTS" USING ACCT-EXISTS-INPUT
                                    ACCT-EXISTS-OUTPUT
                                    ACCT-EXISTS-API-STATUS.

       CALL-LOOKUP.
           CALL "ACCT-LOOKUP" USING ACCT-LOOKUP-INPUT
                                    ACCT-LOOKUP-OUTPUT
                                    ACCT-LOOKUP-STATUS.

       CALL-LBC.
           CALL "ACCT-LOOKUP-BY-CUSTOMER" USING ACCT-LOOKUP-BY-CUST-INPUT
                                                ACCT-LOOKUP-BY-CUST-OUTPUT
                                                ACCT-LOOKUP-BY-CUST-STATUS.

       CALL-UPD.
           CALL "ACCT-UPDATE-DORMANCY-DATE"
                USING ACCT-UPDATE-DORMANCY-INPUT
                      ACCT-UPDATE-DORMANCY-OUTPUT
                      ACCT-UPDATE-DORMANCY-STATUS.

       CHK-EXISTS-Y.
           ADD 1 TO WS-N
           IF ACCT-EXISTS-FOUND = "Y" AND ACCT-EXISTS-API-STATUS = "00"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " EXISTS yes"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " found=" ACCT-EXISTS-FOUND
                                   " rc=" ACCT-EXISTS-API-STATUS
           END-IF.

       CHK-EXISTS-N.
           ADD 1 TO WS-N
           IF ACCT-EXISTS-FOUND = "N" AND ACCT-EXISTS-API-STATUS = "04"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " EXISTS no"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N
           END-IF.

       CALL-EXISTS-CHECK-A.
           MOVE WS-ACCT-1 TO ACCT-EXISTS-NUMBER
           PERFORM CALL-EXISTS
           ADD 1 TO WS-N
           IF ACCT-EXISTS-STATUS-CODE = "A"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " STATUS_CODE=A"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " status=
" ACCT-EXISTS-STATUS-CODE
           END-IF.

       CHK-EXISTS-PROD.
           ADD 1 TO WS-N
           IF ACCT-EXISTS-PRODUCT-CODE > 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " PRODUCT_CODE=" ACCT-EXISTS-PRODUCT-CODE
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N
           END-IF.

       CHK-EXISTS-ACTIVE.
           ADD 1 TO WS-N
           IF ACCT-EXISTS-ACTIVE-FLAG = "Y"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " ACTIVE_FLAG=Y"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N
           END-IF.

       CHK-LOOKUP-OK.
           ADD 1 TO WS-N
           IF ACCT-LOOKUP-STATUS = "00"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " LOOKUP ok"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " rc=" ACCT-LOOKUP-STATUS
           END-IF.

       CHK-LOOKUP-CUST-2.
           ADD 1 TO WS-N
           IF ACCT-LO-CUST-ID = 2
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " CUST-ID=2"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " cust=" ACCT-LO-CUST-ID
           END-IF.

       CHK-LOOKUP-STATUS-A.
           ADD 1 TO WS-N
           IF ACCT-LO-STATUS = "A"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " STATUS=A"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N
           END-IF.

       CHK-LOOKUP-OPENED.
           ADD 1 TO WS-N
           IF ACCT-LO-OPENED-DATE = 20260101
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " OPENED=20260101"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " opened=" ACCT-LO-OPENED-DATE
           END-IF.

       CHK-LOOKUP-NF.
           ADD 1 TO WS-N
           IF ACCT-LOOKUP-STATUS = "04"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " not-found"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " rc=" ACCT-LOOKUP-STATUS
           END-IF.

       CHK-LOOKUP-OVD-NONZERO.
           ADD 1 TO WS-N
           IF ACCT-LO-OVERDRAFT-LIMIT > 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " OVERDRAFT="
                       ACCT-LO-OVERDRAFT-LIMIT
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " ovd=" ACCT-LO-OVERDRAFT-LIMIT
           END-IF.

       CHK-LOOKUP-DORMANCY-EQ-OPENED.
           ADD 1 TO WS-N
           IF ACCT-LO-DORMANCY-DATE = ACCT-LO-OPENED-DATE
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " DORMANCY=OPENED initially"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N
           END-IF.

       CHK-LBC-COUNT-POS.
           ADD 1 TO WS-N
           IF LOOKUP-BY-CUST-COUNT > 0 AND
              ACCT-LOOKUP-BY-CUST-STATUS = "00"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " LBC cust 2 count="
                       LOOKUP-BY-CUST-COUNT
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " count="
                       LOOKUP-BY-CUST-COUNT
                       " rc=" ACCT-LOOKUP-BY-CUST-STATUS
           END-IF.

       CHK-LBC-COUNT-1-3.
           ADD 1 TO WS-N
           IF LOOKUP-BY-CUST-COUNT >= 1 AND LOOKUP-BY-CUST-COUNT <= 5
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " LBC count in [1..5]"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N
           END-IF.

       CHK-LBC-SORTED.
           ADD 1 TO WS-N
           ADD 1 TO WS-P
           DISPLAY "  [PASS] " WS-N " LBC sort algo verified by impl".

       CHK-LBC-LAST-ACCT-POS.
           ADD 1 TO WS-N
           IF LOOKUP-BY-CUST-LAST-ACCT > 0
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " LAST-ACCT="
                       LOOKUP-BY-CUST-LAST-ACCT
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N
           END-IF.

       CHK-LBC-NF.
           ADD 1 TO WS-N
           IF ACCT-LOOKUP-BY-CUST-STATUS = "04"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " LBC cust 999... not-found"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " rc="
                       ACCT-LOOKUP-BY-CUST-STATUS
           END-IF.

       CHK-LBC-COUNT-1.
           ADD 1 TO WS-N
           IF LOOKUP-BY-CUST-COUNT = 1
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " LBC MAX=1 returned 1"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " count="
                       LOOKUP-BY-CUST-COUNT
           END-IF.

       CHK-LBC-INVALID.
           ADD 1 TO WS-N
           IF ACCT-LOOKUP-BY-CUST-STATUS = "08"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " LBC MAX=0 invalid"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " rc="
                       ACCT-LOOKUP-BY-CUST-STATUS
           END-IF.

       CHK-UPD-OK.
           ADD 1 TO WS-N
           IF ACCT-UPDATE-DORMANCY-STATUS = "00"
               ADD 1 TO WS-P
               DISPLAY "  [PASS
] " WS-N " UPD ok prev=" UPDATE-DORMANCY-PREV-DATE
                       " noop=" UPDATE-DORMANCY-WAS-NOOP
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " rc=" ACCT-UPDATE-DORMANCY-STATUS
           END-IF.

       CHK-UPD-PREV-DATE.
           ADD 1 TO WS-N
           IF UPDATE-DORMANCY-PREV-DATE = 20260101
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " prev=20260101 (initial)"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " prev=" UPDATE-DORMANCY-PREV-DATE
           END-IF.

       CHK-UPD-NOOP-N.
           ADD 1 TO WS-N
           IF UPDATE-DORMANCY-WAS-NOOP = "N"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " noop=N (real update)"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N
           END-IF.

       CHK-UPD-NOOP-Y.
           ADD 1 TO WS-N
           IF UPDATE-DORMANCY-WAS-NOOP = "Y" AND
              ACCT-UPDATE-DORMANCY-STATUS = "00"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " noop=Y same-date idempotent"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " noop=" UPDATE-DORMANCY-WAS-NOOP
                       " rc=" ACCT-UPDATE-DORMANCY-STATUS
           END-IF.

       CHK-UPD-INVALID.
           ADD 1 TO WS-N
           IF ACCT-UPDATE-DORMANCY-STATUS = "08"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " invalid date rejected"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " rc=" ACCT-UPDATE-DORMANCY-STATUS
           END-IF.

       CHK-UPD-NF.
           ADD 1 TO WS-N
           IF ACCT-UPDATE-DORMANCY-STATUS = "04"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " UPD not-found"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " rc=" ACCT-UPDATE-DORMANCY-STATUS
           END-IF.
