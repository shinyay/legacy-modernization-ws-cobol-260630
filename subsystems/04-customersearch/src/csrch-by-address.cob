       IDENTIFICATION DIVISION.
       PROGRAM-ID. CSRCH-BY-ADDRESS.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  CUST-INPUT.
           05  CUST-IN-ID          PIC 9(10).
           05  CUST-IN-KANA        PIC X(50).
           05  CUST-IN-PHONE       PIC X(15).
           05  CUST-IN-OP          PIC X(1).
       01  CUST-OUTPUT.
           05  CUST-OUT-STATUS     PIC 9(2).
           05  CUST-OUT-ID         PIC 9(10).
           05  CUST-OUT-KANA       PIC X(50).
           05  CUST-OUT-KANJI      PIC X(60).
           05  CUST-OUT-PHONE      PIC X(15).
           05  CUST-OUT-ADDRESS    PIC X(200).
           05  CUST-OUT-OPENED     PIC 9(8).
           05  CUST-OUT-STATUS-CODE PIC X(1).

       01  WS-SUBSTR-COUNT         PIC 9(4) COMP.
       01  WS-INITIATED            PIC X VALUE 'N'.

       LINKAGE SECTION.
       COPY "csrch-api.cpy".

       PROCEDURE DIVISION USING CSRCH-INPUT CSRCH-OUTPUT.
       MAIN-LOGIC.
           MOVE 0 TO CSRCH-STATUS

           IF CSRCH-OP = "D" THEN
               MOVE "A" TO CUST-IN-OP
               MOVE 0 TO CUST-OUT-STATUS
               MOVE 'Y' TO WS-INITIATED
           END-IF

           IF NOT WS-INITIATED = 'Y'
               MOVE 10 TO CSRCH-STATUS GOBACK
           END-IF

           PERFORM UNTIL CUST-OUT-STATUS = 10
               CALL "CUST-LIST-ALL" USING CUST-INPUT CUST-OUTPUT
               IF CUST-OUT-STATUS = 0
                   MOVE 0 TO WS-SUBSTR-COUNT
                   INSPECT CUST-OUT-ADDRESS
                       TALLYING WS-SUBSTR-COUNT FOR ALL
                       FUNCTION TRIM(CSRCH-ADDR-SUBSTR)
                   IF WS-SUBSTR-COUNT > 0
                       MOVE CUST-OUT-ID    TO CSRCH-MATCH-ID
                       MOVE CUST-OUT-KANA  TO CSRCH-MATCH-KANA
                       MOVE CUST-OUT-KANJI TO CSRCH-MATCH-KANJI
                       MOVE CUST-OUT-PHONE TO CSRCH-MATCH-PHONE
                       MOVE CUST-OUT-ADDRESS TO CSRCH-MATCH-ADDR
                       MOVE 0 TO CSRCH-STATUS
                       MOVE " " TO CUST-IN-OP
                       GOBACK
                   END-IF
               END-IF
               MOVE " " TO CUST-IN-OP
           END-PERFORM

           MOVE 10 TO CSRCH-STATUS
           MOVE 'N' TO WS-INITIATED
           GOBACK.
