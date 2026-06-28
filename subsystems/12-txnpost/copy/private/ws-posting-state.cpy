       01  WS-POSTING-STATE.
           05  WS-TXN-ID                PIC X(18).
           05  WS-POSTING-ID-DR         PIC X(20).
           05  WS-POSTING-ID-CR         PIC X(20).
           05  WS-DR-ACCT               PIC 9(13).
           05  WS-CR-ACCT               PIC 9(13).
           05  WS-LOCK-ACCT-1           PIC 9(13).
           05  WS-LOCK-ACCT-2           PIC 9(13).

           05  WS-TXN-HARD-REJECT-FLAG  PIC X(1) VALUE "N".
               88  WS-TXN-IS-REJECTED               VALUE "Y".
           05  WS-TXN-RECOVERABLE-FAIL  PIC X(1) VALUE "N".
               88  WS-TXN-IS-DEFERRED               VALUE "Y".
           05  WS-TXN-FATAL-FLAG        PIC X(1) VALUE "N".
               88  WS-TXN-IS-FATAL                  VALUE "Y".
           05  WS-TXN-REJECT-REASON     PIC X(4) VALUE SPACES.
           05  WS-TXN-REJECT-TEXT       PIC X(80) VALUE SPACES.

           05  WS-DR-IS-SYS-EXEMPT      PIC X(1) VALUE "N".
               88  WS-DR-EXEMPT                     VALUE "Y".

           05  WS-ATTEMPT-RESULT       PIC X(8) VALUE "OK".
           05  WS-RETRY-COUNT          PIC 9(3) VALUE 0.
           05  WS-MAX-RETRIES          PIC 9(3) VALUE 5.
           05  WS-FSM-DONE             PIC X(1) VALUE "N".
           05  WS-BACKOFF-BASE-MS      PIC 9(6) VALUE 10.
           05  WS-BACKOFF-CAP-MS       PIC 9(6) VALUE 2000.
           05  WS-BACKOFF-MULT         PIC 9(7) VALUE 1.
           05  WS-BACKOFF-N            PIC 9(3) VALUE 0.
           05  WS-BACKOFF-MS           PIC 9(9) VALUE 0.
           05  WS-JITTER-MS            PIC 9(6) VALUE 0.
           05  WS-FAULT-CONFLICT-N     PIC 9(3) VALUE 0.
           05  WS-FAULT-REMAINING      PIC 9(3) VALUE 0.
