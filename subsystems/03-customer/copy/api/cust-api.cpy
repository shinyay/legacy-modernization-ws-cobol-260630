       01  CUST-INPUT.
           05  CUST-IN-ID          PIC 9(10).
           05  CUST-IN-KANA        PIC X(50).
           05  CUST-IN-PHONE       PIC X(15).
           05  CUST-IN-OP          PIC X(1).
               88  CUST-OP-LOOKUP            VALUE "L".
               88  CUST-OP-SEARCH-KANA       VALUE "K".
               88  CUST-OP-SEARCH-PHONE      VALUE "P".
               88  CUST-OP-LIST-ALL          VALUE "A".
               88  CUST-OP-NEXT              VALUE " ".

       01  CUST-OUTPUT.
           05  CUST-OUT-STATUS     PIC 9(2).
               88  CUST-STATUS-OK            VALUE 00.
               88  CUST-STATUS-NOT-FOUND     VALUE 04.
               88  CUST-STATUS-INVALID       VALUE 08.
               88  CUST-STATUS-EOF           VALUE 10.
               88  CUST-STATUS-FATAL         VALUE 16.
           05  CUST-OUT-ID         PIC 9(10).
           05  CUST-OUT-KANA       PIC X(50).
           05  CUST-OUT-KANJI      PIC X(60).
           05  CUST-OUT-PHONE      PIC X(15).
           05  CUST-OUT-ADDRESS    PIC X(200).
           05  CUST-OUT-OPENED     PIC 9(8).
           05  CUST-OUT-STATUS-CODE PIC X(1).

       01  CUST-OPEN-INPUT.
           05  COI-KANA            PIC X(50).
           05  COI-KANJI           PIC X(60).
           05  COI-PHONE           PIC X(15).
           05  COI-ADDRESS         PIC X(200).
           05  COI-BUSINESS-DATE   PIC 9(8).

       01  CUST-STATUS-CHANGE-INPUT.
           05  CSI-ID              PIC 9(10).
           05  CSI-NEW-STATUS      PIC X(1).
           05  CSI-BUSINESS-DATE   PIC 9(8).
