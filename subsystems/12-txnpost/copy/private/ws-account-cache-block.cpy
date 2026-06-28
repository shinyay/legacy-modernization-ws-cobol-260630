       01  WS-ACCT-CACHE-BLOCK.
           05  WS-CURRENT-ACCT-NUMBER   PIC 9(13) VALUE 0.
           05  WS-CURRENT-ACCT-STATUS   PIC X(1)  VALUE SPACES.
               88  WS-CUR-ACCT-APPL              VALUE "P".
               88  WS-CUR-ACCT-ACTIVE            VALUE "A".
               88  WS-CUR-ACCT-DORMANT           VALUE "D".
               88  WS-CUR-ACCT-SUSPENDED         VALUE "S".
               88  WS-CUR-ACCT-CLOSED            VALUE "C".
           05  WS-CURRENT-PRODUCT-CODE  PIC 9(3)  VALUE 0.
           05  WS-CURRENT-OVERDRAFT     PIC S9(15) COMP-3 VALUE 0.
           05  WS-BLOCK-OPEN-FLAG       PIC X(1)  VALUE "N".
               88  WS-BLOCK-IS-OPEN              VALUE "Y".
           05  WS-BLOCK-TXN-COUNT       PIC 9(7)  VALUE 0.
           05  WS-BLOCK-POSTED-COUNT    PIC 9(7)  VALUE 0.
           05  WS-BLOCK-ALL-REJECT-FLAG PIC X(1)  VALUE "N".
               88  WS-BLOCK-ALL-REJECTED         VALUE "Y".
           05  WS-BLOCK-REJECT-REASON   PIC X(4)  VALUE SPACES.

           05  WS-CASH-ACCOUNT          PIC 9(13)
                                            VALUE 0010010000001.
           05  WS-CLEARING-ACCOUNT      PIC 9(13)
                                            VALUE 0010010000002.
