       FD  CUST-SEED-FILE.
       01  CS-REC.
           05  CS-ID               PIC 9(10).
           05  CS-KANA             PIC X(50).
           05  CS-KANJI            PIC X(60).
           05  CS-PHONE            PIC X(15).
           05  CS-ADDRESS          PIC X(200).
           05  CS-OPENED-DATE      PIC 9(8).
           05  CS-STATUS           PIC X(1).
           05  CS-CREATED-TS       PIC 9(14).
           05  CS-UPDATED-TS       PIC 9(14).
           05  CS-TIER             PIC X(1).
           05  CS-FILLER           PIC X(19).
