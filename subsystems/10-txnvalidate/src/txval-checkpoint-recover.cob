       IDENTIFICATION DIVISION.
       PROGRAM-ID. TXVAL-CHECKPOINT-RECOVER.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TXN-CHECKPOINT-FILE
               ASSIGN TO WS-CKPT-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FS.

       DATA DIVISION.
       FILE SECTION.
           COPY "fd-txn-checkpoint.cpy".

       WORKING-STORAGE SECTION.
       01  WS-CKPT-PATH         PIC X(80) VALUE SPACES.
       01  WS-FS                PIC X(2).
       01  WS-READ-FAIL         PIC X(1) VALUE "N".

       LINKAGE SECTION.
           COPY "tx-val-api.cpy".

       PROCEDURE DIVISION USING TXVAL-CKPT-RECOVER-INPUT
                                TXVAL-CKPT-RECOVER-OUTPUT.
       MAIN-LOGIC.
           MOVE FUNCTION TRIM(TXVAL-CR-IN-FILENAME)
               TO WS-CKPT-PATH
           MOVE 0 TO TXVAL-CR-OUT-LAST-SEQ
           OPEN INPUT TXN-CHECKPOINT-FILE
           EVALUATE WS-FS
               WHEN "00"
                   PERFORM READ-AND-PARSE
                   CLOSE TXN-CHECKPOINT-FILE
                   IF WS-READ-FAIL = "Y"
                       SET TXVAL-CR-CORRUPT TO TRUE
                   ELSE
                       SET TXVAL-CR-FOUND TO TRUE
                   END-IF
               WHEN "35"
                   SET TXVAL-CR-NO-CHECKPOINT TO TRUE
                   MOVE 0 TO TXVAL-CR-OUT-LAST-SEQ
               WHEN OTHER
                   SET TXVAL-CR-FATAL TO TRUE
           END-EVALUATE
           GOBACK.

       READ-AND-PARSE.
           READ TXN-CHECKPOINT-FILE
               AT END
                   MOVE "Y" TO WS-READ-FAIL
                   EXIT PARAGRAPH
           END-READ
           IF TC-SENTINEL NOT = "OK"
               MOVE "Y" TO WS-READ-FAIL
               EXIT PARAGRAPH
           END-IF
           MOVE TC-LAST-SEQ TO TXVAL-CR-OUT-LAST-SEQ.

       END PROGRAM TXVAL-CHECKPOINT-RECOVER.
