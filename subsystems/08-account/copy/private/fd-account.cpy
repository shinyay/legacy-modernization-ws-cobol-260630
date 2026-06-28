       FD  ACCOUNT-FILE.
       01  ACCT-REC.
           05  ACCT-REC-NUMBER         PIC 9(13).
           05  ACCT-REC-CUST-ID        PIC 9(10).
           05  ACCT-REC-PRODUCT-CODE   PIC 9(3).
           05  ACCT-REC-BRANCH-CODE    PIC 9(3).
           05  ACCT-REC-OPENED-DATE    PIC 9(8).
           05  ACCT-REC-CLOSED-DATE    PIC 9(8).
           05  ACCT-REC-STATUS         PIC X(1).
           05  ACCT-REC-OVERDRAFT      PIC S9(15) COMP-3.
           05  ACCT-REC-TERM-DAYS      PIC 9(4).
           05  ACCT-REC-DORMANCY-DATE  PIC 9(8).
           05  ACCT-REC-CREATED-TS     PIC 9(14).
           05  ACCT-REC-UPDATED-TS     PIC 9(14).
           05  ACCT-REC-FILLER         PIC X(16).
