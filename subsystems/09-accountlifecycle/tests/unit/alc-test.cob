       IDENTIFICATION DIVISION.
       PROGRAM-ID. ALCTEST.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "alc-api.cpy".

       01  WS-N PIC 9(3) VALUE 0.
       01  WS-P PIC 9(3) VALUE 0.
       01  WS-F PIC 9(3) VALUE 0.

       01  WS-TEST-ACCT  PIC 9(13) VALUE 0010030000001.
       01  WS-NEW-ACCT   PIC 9(13).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           DISPLAY "=== 09-accountlifecycle FSM tests ===".

           DISPLAY " ".
           DISPLAY "--- ALC-OPEN (4 cases) ---".

           MOVE 0000000099 TO ALC-OPEN-CUST-ID
           MOVE 001 TO ALC-OPEN-PRODUCT-CODE
           MOVE 001 TO ALC-OPEN-BRANCH-CODE
           MOVE 20260601 TO ALC-OPEN-OPENED-DATE
           MOVE 0 TO ALC-OPEN-OVERDRAFT-LIMIT
           MOVE 0 TO ALC-OPEN-TERM-DAYS
           CALL "ALC-OPEN" USING ALC-OPEN-INPUT
                                 ALC-OPEN-OUTPUT
                                 ALC-OPEN-STATUS
           ADD 1 TO WS-N
           IF ALC-OPEN-STATUS = "00" AND ALC-OPEN-ACCT-NUMBER > 0
               ADD 1 TO WS-P
               MOVE ALC-OPEN-ACCT-NUMBER TO WS-NEW-ACCT
               DISPLAY "  [PASS] " WS-N " ALC-OPEN ok acct=" WS-NEW-ACCT
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " rc=" ALC-OPEN-STATUS
                       " acct=" ALC-OPEN-ACCT-NUMBER
           END-IF

           MOVE 0 TO ALC-OPEN-CUST-ID
           CALL "ALC-OPEN" USING ALC-OPEN-INPUT
                                 ALC-OPEN-OUTPUT
                                 ALC-OPEN-STATUS
           ADD 1 TO WS-N
           IF ALC-OPEN-STATUS = "08"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " ALC-OPEN invalid cust=0"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " rc=" ALC-OPEN-STATUS
           END-IF

           MOVE 0000000099 TO ALC-OPEN-CUST-ID
           MOVE 0 TO ALC-OPEN-BRANCH-CODE
           CALL "ALC-OPEN" USING ALC-OPEN-INPUT
                                 ALC-OPEN-OUTPUT
                                 ALC-OPEN-STATUS
           ADD 1 TO WS-N
           IF ALC-OPEN-STATUS = "08"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " ALC-OPEN invalid branch=0"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N
           END-IF

           MOVE 0000000099 TO ALC-OPEN-CUST-ID
           MOVE 001 TO ALC-OPEN-BRANCH-CODE
           MOVE 002 TO ALC-OPEN-PRODUCT-CODE
           MOVE 0 TO ALC-OPEN-OVERDRAFT-LIMIT
           MOVE 365 TO ALC-OPEN-TERM-DAYS
           CALL "ALC-OPEN" USING ALC-OPEN-INPUT
                                 ALC-OPEN-OUTPUT
                                 ALC-OPEN-STATUS
           ADD 1 TO WS-N
           IF ALC-OPEN-STATUS = "00"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " 2nd ALC-OPEN ok"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " rc=" ALC-OPEN-STATUS
           END-IF

           DISPLAY " ".
           DISPLAY "--- ALC-CHANGE-STATE FSM (12 cases) ---".

           MOVE WS-NEW-ACCT TO ALC-CHANGE-ACCT-NUMBER
           MOVE "AC" TO ALC-CHANGE-ACTION-CODE
           MOVE SPACES TO ALC-CHANGE-REASON-TEXT
           MOVE 20260601 TO ALC-CHANGE-BUSINESS-DATE
           CALL "ALC-CHANGE-STATE" USING ALC-CHANGE-INPUT
                                         ALC-CHANGE-OUTPUT
                                         ALC-CHANGE-STATUS
           PERFORM CHK-CHANGE-OK-P-A

           MOVE "SU" TO ALC-CHANGE-ACTION-CODE
           MOVE "fraud investigation" TO ALC-CHANGE-REASON-TEXT
           CALL "ALC-CHANGE-STATE" USING ALC-CHANGE-INPUT
                                         ALC-CHANGE-OUTPUT
                                         ALC-CHANGE-STATUS
           PERFORM CHK-CHANGE-OK-A-S

           MOVE "SU" TO ALC-CHANGE-ACTION-CODE
           MOVE SPACES TO ALC-CHANGE-REASON-TEXT
           CALL "ALC-CHANGE-STATE" USING ALC-CHANGE-INPUT
                                         ALC-CHANGE-OUTPUT
                                         ALC-CHANGE-STATUS
           PERFORM CHK-CHANGE-INVALID

           MOVE "LS" TO ALC-CHANGE-ACTION-CODE
           CALL "ALC-CHANGE-STATE" USING ALC-CHANGE-INPUT
                                         ALC-CHANGE-OUTPUT
                                         ALC-CHANGE-STATUS
           PERFORM CHK-CHANGE-OK-S-A

           MOVE "ZZ" TO ALC-CHANGE-ACTION-CODE
           CALL "ALC-CHANGE-STATE" USING ALC-CHANGE-INPUT
                                         ALC-CHANGE-OUTPUT
                                         ALC-CHANGE-STATUS
           PERFORM CHK-CHANGE-INVALID

           MOVE 9999999999999 TO ALC-CHANGE-ACCT-NUMBER
           MOVE "AC" TO ALC-CHANGE-ACTION-CODE
           CALL "ALC-CHANGE-STATE" USING ALC-CHANGE-INPUT
                                         ALC-CHANGE-OUTPUT
                                         ALC-CHANGE-STATUS
           PERFORM CHK-CHANGE-NF

           MOVE WS-NEW-ACCT TO ALC-CHANGE-ACCT-NUMBER
           MOVE "AC" TO ALC-CHANGE-ACTION-CODE
           CALL "ALC-CHANGE-STATE" USING ALC-CHANGE-INPUT
                                         ALC-CHANGE-OUTPUT
                                         ALC-CHANGE-STATUS
           PERFORM CHK-CHANGE-INVALID

           MOVE "CL" TO ALC-CHANGE-ACTION-CODE
           CALL "ALC-CHANGE-STATE" USING ALC-CHANGE-INPUT
                                         ALC-CHANGE-OUTPUT
                                         ALC-CHANGE-STATUS
           PERFORM CHK-CHANGE-OK

           MOVE "AC" TO ALC-CHANGE-ACTION-CODE
           CALL "ALC-CHANGE-STATE" USING ALC-CHANGE-INPUT
                                         ALC-CHANGE-OUTPUT
                                         ALC-CHANGE-STATUS
           PERFORM CHK-CHANGE-INVALID

           MOVE WS-TEST-ACCT TO ALC-CHANGE-ACCT-NUMBER
           MOVE "FC" TO ALC-CHANGE-ACTION-CODE
           MOVE "operator forced" TO ALC-CHANGE-REASON-TEXT
           CALL "ALC-CHANGE-STATE" USING ALC-CHANGE-INPUT
                                         ALC-CHANGE-OUTPUT
                                         ALC-CHANGE-STATUS
           PERFORM CHK-CHANGE-OK

           MOVE 0000000099 TO ALC-OPEN-CUST-ID
           MOVE 003 TO ALC-OPEN-PRODUCT-CODE
           MOVE 005 TO ALC-OPEN-BRANCH-CODE
           MOVE 20260601 TO ALC-OPEN-OPENED-DATE
           MOVE 0 TO ALC-OPEN-OVERDRAFT-LIMIT
           MOVE 0 TO ALC-OPEN-TERM-DAYS
           CALL "ALC-OPEN" USING ALC-OPEN-INPUT
                                 ALC-OPEN-OUTPUT
                                 ALC-OPEN-STATUS
           MOVE ALC-OPEN-ACCT-NUMBER TO ALC-CHANGE-ACCT-NUMBER
           MOVE "CN" TO ALC-CHANGE-ACTION-CODE
           CALL "ALC-CHANGE-STATE" USING ALC-CHANGE-INPUT
                                         ALC-CHANGE-OUTPUT
                                         ALC-CHANGE-STATUS
           PERFORM CHK-CHANGE-OK

           MOVE 0000000099 TO ALC-OPEN-CUST-ID
           MOVE 003 TO ALC-OPEN-PRODUCT-CODE
           MOVE 010 TO ALC-OPEN-BRANCH-CODE
           CALL "ALC-OPEN" USING ALC-OPEN-INPUT
                                 ALC-OPEN-OUTPUT
                                 ALC-OPEN-STATUS
           MOVE ALC-OPEN-ACCT-NUMBER TO ALC-CHANGE-ACCT-NUMBER
           MOVE "SU" TO ALC-CHANGE-ACTION-CODE
           MOVE "test reason" TO ALC-CHANGE-REASON-TEXT
           CALL "ALC-CHANGE-STATE" USING ALC-CHANGE-INPUT
                                         ALC-CHANGE-OUTPUT
                                         ALC-CHANGE-STATUS
           PERFORM CHK-CHANGE-INVALID

           DISPLAY " ".
           DISPLAY "--- ALC-DORMANCY-SCAN (1 case) ---".

           MOVE 20290601 TO ALC-DORMANCY-BUSINESS-DATE
           CALL "ALC-DORMANCY-SCAN" USING ALC-DORMANCY-SCAN-INPUT
                                          ALC-DORMANCY-SCAN-OUTPUT
                                          ALC-DORMANCY-SCAN-STATUS
           ADD 1 TO WS-N
           IF ALC-DORMANCY-SCAN-STATUS = "00" OR
              ALC-DORMANCY-SCAN-STATUS = "04"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N
                       " DORMANCY-SCAN rc=" ALC-DORMANCY-SCAN-STATUS
                       " transitioned=" ALC-DORMANCY-TRANSITIONED
                       " skipped=" ALC-DORMANCY-SKIPPED
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N
                       " rc=" ALC-DORMANCY-SCAN-STATUS
           END-IF

           DISPLAY " ".
           DISPLAY "--- ALC-REACTIVATION-SCAN MVP stub (1 case) ---".

           MOVE 20260601 TO ALC-REACT-BUSINESS-DATE
           CALL "ALC-REACTIVATION-SCAN" USING ALC-REACTIVATION-SCAN-INPUT
                                              ALC-REACTIVATION-SCAN-OUTPUT
                                              ALC-REACTIVATION-SCAN-STATUS
           ADD 1 TO WS-N
           IF ALC-REACTIVATION-SCAN-STATUS = "04"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " REACT-SCAN stub returns 04"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N
           END-IF

           DISPLAY " ".
           DISPLAY "=== Total: " WS-N
                   " | PASS: " WS-P
                   " | FAIL: " WS-F.
           IF WS-F > 0 MOVE 1 TO RETURN-CODE END-IF
           STOP RUN.

       CHK-CHANGE-OK.
           ADD 1 TO WS-N
           IF ALC-CHANGE-STATUS = "00"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " transition "
                       ALC-CHANGE-FROM-STATUS " -> "
                       ALC-CHANGE-TARGET-STATUS
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " rc=" ALC-CHANGE-STATUS
           END-IF.

       CHK-CHANGE-OK-P-A.
           ADD 1 TO WS-N
           IF ALC-CHANGE-STATUS = "00" AND
              ALC-CHANGE-FROM-STATUS = "P" AND
              ALC-CHANGE-TARGET-STATUS = "A"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " P->A activate"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " from=" ALC-CHANGE-FROM-STATUS
                       " to=" ALC-CHANGE-TARGET-STATUS
                       " rc=" ALC-CHANGE-STATUS
           END-IF.

       CHK-CHANGE-OK-A-S.
           ADD 1 TO WS-N
           IF ALC-CHANGE-STATUS = "00" AND
              ALC-CHANGE-FROM-STATUS = "A" AND
              ALC-CHANGE-TARGET-STATUS = "S"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " A->S suspend"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N
           END-IF.

       CHK-CHANGE-OK-S-A.
           ADD 1 TO WS-N
           IF ALC-CHANGE-STATUS = "00" AND
              ALC-CHANGE-FROM-STATUS = "S" AND
              ALC-CHANGE-TARGET-STATUS = "A"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " S->A lift-suspend"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N
           END-IF.

       CHK-CHANGE-INVALID.
           ADD 1 TO WS-N
           IF ALC-CHANGE-STATUS = "08"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " rejected (08)"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " rc=" ALC-CHANGE-STATUS
           END-IF.

       CHK-CHANGE-NF.
           ADD 1 TO WS-N
           IF ALC-CHANGE-STATUS = "04"
               ADD 1 TO WS-P
               DISPLAY "  [PASS] " WS-N " not-found (04)"
           ELSE ADD 1 TO WS-F
                DISPLAY "  [FAIL] " WS-N " rc=" ALC-CHANGE-STATUS
           END-IF.
