       FD  CUSTOMER-FILE.
       01  CUST-REC.
           05  CR-ID               PIC 9(10).
           05  CR-KANA             PIC X(50).
           05  CR-KANJI            PIC X(60).
           05  CR-PHONE            PIC X(15).
           05  CR-ADDRESS          PIC X(200).
           05  CR-OPENED-DATE      PIC 9(8).
           05  CR-STATUS           PIC X(1).
           05  CR-CREATED-TS       PIC 9(14).
           05  CR-UPDATED-TS       PIC 9(14).
           05  CR-TIER             PIC X(1).
           05  CR-FILLER           PIC X(19).
