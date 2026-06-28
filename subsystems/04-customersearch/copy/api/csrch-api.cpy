       01  CSRCH-INPUT.
           05  CSRCH-KANA-PREFIX   PIC X(50).
           05  CSRCH-PHONE-PREFIX  PIC X(15).
           05  CSRCH-ADDR-SUBSTR   PIC X(50).
           05  CSRCH-PAGE-SIZE     PIC 9(3).
           05  CSRCH-START-AFTER   PIC 9(10).
           05  CSRCH-OP            PIC X(1).
               88  CSRCH-OP-AND        VALUE "A".
               88  CSRCH-OP-ADDRESS    VALUE "D".
               88  CSRCH-OP-PAGED      VALUE "P".
               88  CSRCH-OP-NEXT       VALUE " ".

       01  CSRCH-OUTPUT.
           05  CSRCH-STATUS        PIC 9(2).
               88  CSRCH-OK            VALUE 00.
               88  CSRCH-EOF           VALUE 10.
               88  CSRCH-FATAL         VALUE 16.
           05  CSRCH-MATCH-ID      PIC 9(10).
           05  CSRCH-MATCH-KANA    PIC X(50).
           05  CSRCH-MATCH-KANJI   PIC X(60).
           05  CSRCH-MATCH-PHONE   PIC X(15).
           05  CSRCH-MATCH-ADDR    PIC X(200).
           05  CSRCH-LAST-ID       PIC 9(10).
