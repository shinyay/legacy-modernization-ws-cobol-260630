       01  AD-FAILED-REC.
           05  ADF-INSTRUCTION-ID    PIC X(20).
           05  ADF-BUSINESS-DATE     PIC 9(8).
           05  ADF-PAYER-ACCOUNT     PIC X(13).
           05  ADF-PAYEE-NAME        PIC X(80).
           05  ADF-AMOUNT-JPY        PIC 9(15).
           05  ADF-REASON-CODE       PIC X(2).
           05  ADF-REASON-EXPANDED   PIC X(20).
           05  ADF-CONSECUTIVE-FAILS PIC 9(2).
           05  ADF-NEXT-ATTEMPT-DATE PIC 9(8).
           05  ADF-ATTEMPTED-AT-TS   PIC 9(14).
           05  ADF-FILLER            PIC X(18).
