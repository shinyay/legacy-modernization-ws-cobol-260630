       DEH-VALIDATE.
           MOVE 0       TO DEH-RC.
           MOVE SPACES  TO DEH-MSG.

           EVALUATE DEH-CAT
               WHEN 10
               WHEN 20
               WHEN 30
               WHEN 40
               WHEN 50
               WHEN 60
                   CONTINUE
               WHEN OTHER
                   MOVE 30 TO DEH-RC
                   MOVE "Invalid category (must be 10/20/30/40/50/60)"
                       TO DEH-MSG
           END-EVALUATE.

           IF DEH-RC NOT = 0 THEN
               EXIT PARAGRAPH
           END-IF.

           IF DEH-DR-ACCT = SPACES OR DEH-CR-ACCT = SPACES THEN
               MOVE 40 TO DEH-RC
               MOVE "Blank DR or CR account" TO DEH-MSG
               EXIT PARAGRAPH
           END-IF.

           EVALUATE DEH-CAT
               WHEN 10
                   IF DEH-AMOUNT-JPY <= 0 THEN
                       MOVE 20 TO DEH-RC
                       MOVE "Cat 10 deposit requires positive amount"
                           TO DEH-MSG
                   END-IF
               WHEN 20
                   IF DEH-AMOUNT-JPY >= 0 THEN
                       MOVE 20 TO DEH-RC
                       MOVE "Cat 20 withdrawal requires negative amount"
                           TO DEH-MSG
                   END-IF
               WHEN 30
                   IF DEH-AMOUNT-JPY = 0 THEN
                       MOVE 20 TO DEH-RC
                       MOVE "Cat 30 transfer requires non-zero amount"
                           TO DEH-MSG
                   END-IF
               WHEN 40
                   IF DEH-AMOUNT-JPY >= 0 THEN
                       MOVE 20 TO DEH-RC
                       MOVE "Cat 40 wire-out requires negative amount"
                           TO DEH-MSG
                   END-IF
               WHEN 50
                   IF DEH-AMOUNT-JPY <= 0 THEN
                       MOVE 20 TO DEH-RC
                       MOVE "Cat 50 interest requires positive amount"
                           TO DEH-MSG
                   END-IF
               WHEN 60
                   IF DEH-AMOUNT-JPY >= 0 THEN
                       MOVE 20 TO DEH-RC
                       MOVE "Cat 60 fee requires negative amount"
                           TO DEH-MSG
                   END-IF
           END-EVALUATE.
