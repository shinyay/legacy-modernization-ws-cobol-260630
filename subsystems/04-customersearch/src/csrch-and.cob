       IDENTIFICATION DIVISION.
       PROGRAM-ID. CSRCH-AND.
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

       01  WS-KANA-RESULTS.
           05  WS-KANA-COUNT       PIC 9(4) VALUE 0.
           05  WS-KANA-IDS         OCCURS 200 TIMES PIC 9(10).
       01  WS-PHONE-RESULTS.
           05  WS-PHONE-COUNT      PIC 9(4) VALUE 0.
           05  WS-PHONE-IDS        OCCURS 200 TIMES PIC 9(10).
       01  WS-MATCH-RESULTS.
           05  WS-MATCH-COUNT      PIC 9(4) VALUE 0.
           05  WS-MATCH-CURSOR     PIC 9(4) VALUE 0.
           05  WS-MATCH-IDS        OCCURS 100 TIMES PIC 9(10).
       01  WS-LOADED-FLAG          PIC X VALUE 'N'.
       01  WS-I                    PIC 9(4) COMP.
       01  WS-J                    PIC 9(4) COMP.

       LINKAGE SECTION.
       COPY "csrch-api.cpy".

       PROCEDURE DIVISION USING CSRCH-INPUT CSRCH-OUTPUT.
       MAIN-LOGIC.
           MOVE 0 TO CSRCH-STATUS

           IF CSRCH-OP = "A" THEN
               MOVE 0 TO WS-KANA-COUNT WS-PHONE-COUNT
                         WS-MATCH-COUNT WS-MATCH-CURSOR
               PERFORM POPULATE-KANA
               PERFORM POPULATE-PHONE
               PERFORM INTERSECT
               MOVE 'Y' TO WS-LOADED-FLAG
           END-IF

           IF NOT WS-LOADED-FLAG = 'Y' THEN
               MOVE 10 TO CSRCH-STATUS GOBACK
           END-IF

           ADD 1 TO WS-MATCH-CURSOR
           IF WS-MATCH-CURSOR > WS-MATCH-COUNT THEN
               MOVE 10 TO CSRCH-STATUS GOBACK
           END-IF

           MOVE WS-MATCH-IDS(WS-MATCH-CURSOR) TO CUST-IN-ID
           CALL "CUST-LOOKUP" USING CUST-INPUT CUST-OUTPUT
           IF CUST-OUT-STATUS = 0 THEN
               MOVE CUST-OUT-ID    TO CSRCH-MATCH-ID
               MOVE CUST-OUT-KANA  TO CSRCH-MATCH-KANA
               MOVE CUST-OUT-KANJI TO CSRCH-MATCH-KANJI
               MOVE CUST-OUT-PHONE TO CSRCH-MATCH-PHONE
               MOVE CUST-OUT-ADDRESS TO CSRCH-MATCH-ADDR
               MOVE 0 TO CSRCH-STATUS
           ELSE
               MOVE 16 TO CSRCH-STATUS
           END-IF
           GOBACK.

       POPULATE-KANA.
           MOVE CSRCH-KANA-PREFIX TO CUST-IN-KANA
           MOVE "K" TO CUST-IN-OP
           MOVE 0 TO CUST-OUT-STATUS
           PERFORM UNTIL CUST-OUT-STATUS = 10 OR WS-KANA-COUNT >= 200
               CALL "CUST-SEARCH-BY-KANA" USING CUST-INPUT CUST-OUTPUT
               IF CUST-OUT-STATUS = 0
                   ADD 1 TO WS-KANA-COUNT
                   MOVE CUST-OUT-ID TO WS-KANA-IDS(WS-KANA-COUNT)
               END-IF
               MOVE " " TO CUST-IN-OP
           END-PERFORM.

       POPULATE-PHONE.
           MOVE CSRCH-PHONE-PREFIX TO CUST-IN-PHONE
           MOVE "P" TO CUST-IN-OP
           MOVE 0 TO CUST-OUT-STATUS
           PERFORM UNTIL CUST-OUT-STATUS = 10 OR WS-PHONE-COUNT >= 200
               CALL "CUST-SEARCH-BY-PHONE" USING CUST-INPUT CUST-OUTPUT
               IF CUST-OUT-STATUS = 0
                   ADD 1 TO WS-PHONE-COUNT
                   MOVE CUST-OUT-ID TO WS-PHONE-IDS(WS-PHONE-COUNT)
               END-IF
               MOVE " " TO CUST-IN-OP
           END-PERFORM.

       INTERSECT.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-KANA-COUNT
               PERFORM VARYING WS-J FROM 1 BY 1 UNTIL WS-J > WS-PHONE-COUNT
                   IF WS-KANA-IDS(WS-I) = WS-PHONE-IDS(WS-J)
                      AND WS-MATCH-COUNT < 100 THEN
                       ADD 1 TO WS-MATCH-COUNT
                       MOVE WS-KANA-IDS(WS-I)
                            TO WS-MATCH-IDS(WS-MATCH-COUNT)
                   END-IF
               END-PERFORM
           END-PERFORM.
