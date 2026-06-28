       01  WS-PREV-KEY.
           05  WS-PREV-PAYER-ACCT       PIC X(13) VALUE SPACES.
           05  WS-PREV-SEQ              PIC 9(10) VALUE 0.

       01  WS-RECON-SCAN-PREV.
           05  WS-RSP-PAYER-ACCT        PIC X(13) VALUE SPACES.
           05  WS-RSP-SEQ               PIC 9(10) VALUE 0.
           05  WS-RSP-FIRST             PIC X(1) VALUE "Y".
               88  WS-RSP-IS-FIRST              VALUE "Y".

       01  WS-SORTED-CUR.
           05  WS-SORTED-CUR-REC        PIC X(600) VALUE SPACES.
           05  WS-SORTED-KEY.
               10  WS-SORTED-K-PAYER    PIC X(13) VALUE SPACES.
               10  WS-SORTED-K-SEQ      PIC 9(10) VALUE 0.
           05  WS-SORTED-EOF            PIC X(1) VALUE "N".
               88  WS-SORTED-IS-EOF             VALUE "Y".

       01  WS-RECON-CUR.
           05  WS-RECON-CUR-REC         PIC X(600) VALUE SPACES.
           05  WS-RECON-KEY.
               10  WS-RECON-K-PAYER     PIC X(13) VALUE SPACES.
               10  WS-RECON-K-SEQ       PIC 9(10) VALUE 0.
           05  WS-RECON-EOF             PIC X(1) VALUE "N".
               88  WS-RECON-IS-EOF              VALUE "Y".

       01  WS-TEMP-COPY-EOF             PIC X(1) VALUE "N".
           88  WS-TEMP-COPY-IS-EOF              VALUE "Y".

       01  WS-RECON-EXISTS              PIC 9(1) VALUE 0.
           88  WS-RECON-PRESENT                  VALUE 1.
