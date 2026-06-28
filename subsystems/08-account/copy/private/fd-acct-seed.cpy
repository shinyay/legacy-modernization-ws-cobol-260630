       FD  ACCT-SEED-FILE
           RECORD CONTAINS 110 CHARACTERS.
       01  ACCT-SEED-REC.
           05  AS-NUMBER         PIC 9(13).
           05  AS-CUST-ID        PIC 9(10).
           05  AS-PRODUCT-CODE   PIC 9(3).
           05  AS-BRANCH-CODE    PIC 9(3).
           05  AS-OPENED-DATE    PIC 9(8).
           05  AS-CLOSED-DATE    PIC 9(8).
           05  AS-STATUS         PIC X(1).
           05  AS-OVERDRAFT      PIC S9(15) COMP-3.
           05  AS-TERM-DAYS      PIC 9(4).
           05  AS-DORMANCY-DATE  PIC 9(8).
           05  AS-CREATED-TS     PIC 9(14).
           05  AS-UPDATED-TS     PIC 9(14).
           05  AS-FILLER         PIC X(16).
