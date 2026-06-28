       01  WS-ATTEMPT-RESULT         PIC X(8) VALUE "OK".
       01  WS-RETRY-COUNT            PIC 9(3) VALUE 0.
       01  WS-MAX-RETRIES            PIC 9(3) VALUE 5.
       01  WS-FSM-DONE               PIC X(1) VALUE "N".
       01  WS-SER-STOP-FLAG          PIC X(1) VALUE "N".
           88  WS-SER-STOP                   VALUE "Y".
       01  WS-SER-RETRIES-TOTAL      PIC 9(7) VALUE 0.
       01  WS-BACKOFF-BASE-MS        PIC 9(6) VALUE 10.
       01  WS-BACKOFF-CAP-MS         PIC 9(6) VALUE 2000.
       01  WS-BACKOFF-MULT           PIC 9(7) VALUE 1.
       01  WS-BACKOFF-N              PIC 9(3) VALUE 0.
       01  WS-BACKOFF-MS             PIC 9(9) VALUE 0.
       01  WS-JITTER-MS              PIC 9(6) VALUE 0.
       01  WS-BACKOFF-NANOS          PIC 9(10) VALUE 0.
       01  WS-FAULT-CONFLICT-N       PIC 9(3) VALUE 0.
       01  WS-FAULT-REMAINING        PIC 9(3) VALUE 0.
       01  WS-SER-CONFIG-WK.
           05  WS-ENV-BUF            PIC X(16) VALUE SPACES.
           05  WS-FUNC-DATE-BUF      PIC X(21) VALUE SPACES.
           05  WS-RAND-SEED          PIC 9(9) VALUE 0.
           05  WS-RAND-INIT          PIC 9V9(4) VALUE 0.
       01  WS-SER-CTX                PIC X(18) VALUE SPACES.
       01  WS-SER-SUBSYS             PIC X(12) VALUE SPACES.
