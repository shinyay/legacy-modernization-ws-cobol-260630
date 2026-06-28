       01  WS-RC-CODES.
           05  WS-RC-OK             PIC 9(2) VALUE  0.
           05  WS-RC-WARN           PIC 9(2) VALUE  4.
           05  WS-RC-RECOVERABLE    PIC 9(2) VALUE  8.
           05  WS-RC-OPERATOR       PIC 9(2) VALUE 12.
           05  WS-RC-FATAL          PIC 9(2) VALUE 16.

       01  WS-FS-CODES.
           05  WS-FS-OK             PIC X(2) VALUE "00".
           05  WS-FS-OK-DUP-ALT     PIC X(2) VALUE "02".
           05  WS-FS-WRONG-LENGTH   PIC X(2) VALUE "04".
           05  WS-FS-OPT-NOT-PRES   PIC X(2) VALUE "05".
           05  WS-FS-EOF            PIC X(2) VALUE "10".
           05  WS-FS-KEY-OOR        PIC X(2) VALUE "14".
           05  WS-FS-SEQ-ERR        PIC X(2) VALUE "21".
           05  WS-FS-DUP-KEY        PIC X(2) VALUE "22".
           05  WS-FS-NOT-FOUND      PIC X(2) VALUE "23".
           05  WS-FS-DISK-FULL      PIC X(2) VALUE "24".
           05  WS-FS-PERM-IO-30     PIC X(2) VALUE "30".
           05  WS-FS-FILE-NOT-EXIST PIC X(2) VALUE "35".
           05  WS-FS-ATTR-CONFLICT  PIC X(2) VALUE "39".

       01  WS-AUD-RC-CODES.
           05  WS-AUD-RC-OK         PIC 9(2) VALUE  0.
           05  WS-AUD-RC-TRANSIENT  PIC 9(2) VALUE  2.
           05  WS-AUD-RC-FATAL      PIC 9(2) VALUE  8.

       01  WS-LOG-RC-CODES.
           05  WS-LOG-RC-OK         PIC 9(2) VALUE  0.
           05  WS-LOG-RC-FALLBACK   PIC 9(2) VALUE  2.
           05  WS-LOG-RC-FATAL      PIC 9(2) VALUE  8.

       01  WS-LOG-LEVELS.
           05  WS-LOG-LEVEL-DEBUG   PIC X(5) VALUE "DEBUG".
           05  WS-LOG-LEVEL-INFO    PIC X(5) VALUE "INFO ".
           05  WS-LOG-LEVEL-WARN    PIC X(5) VALUE "WARN ".
           05  WS-LOG-LEVEL-ERROR   PIC X(5) VALUE "ERROR".

       01  WS-AUD-SEVERITIES.
           05  WS-AUD-SEV-INFO      PIC X(1) VALUE "I".
           05  WS-AUD-SEV-WARN      PIC X(1) VALUE "W".
           05  WS-AUD-SEV-ERROR     PIC X(1) VALUE "E".
           05  WS-AUD-SEV-CRITICAL  PIC X(1) VALUE "C".
