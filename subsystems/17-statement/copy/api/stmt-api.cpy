       01  STMT-INPUT.
           05  STMT-BATCH-ID               PIC X(14).
           05  STMT-BUSINESS-DATE          PIC 9(8).
           05  STMT-MODE                   PIC X(1).
               88  STMT-MODE-DAILY                  VALUE "D".
               88  STMT-MODE-MONTHLY                VALUE "M".
           05  STMT-OUTPUT-FILENAME        PIC X(80).
           05  STMT-SUMMARY-FILENAME       PIC X(80).
           05  STMT-SKIP-INACTIVE          PIC X(1).
               88  STMT-SKIP-INACTIVE-YES           VALUE "Y".
               88  STMT-SKIP-INACTIVE-NO            VALUE "N".

       01  STMT-OUTPUT.
           05  STMT-STATUS                 PIC X(2).
               88  STMT-OK                          VALUE "00".
               88  STMT-PARTIAL                     VALUE "04".
               88  STMT-INVALID-INPUT               VALUE "08".
               88  STMT-IO-FAIL                     VALUE "12".
               88  STMT-FATAL                       VALUE "16".
           05  STMT-OUT-ACCOUNTS-PROCESSED PIC 9(7).
           05  STMT-OUT-ACCOUNTS-EMPTY     PIC 9(7).
           05  STMT-OUT-ACCOUNTS-SKIPPED   PIC 9(7).
           05  STMT-OUT-LINES-WRITTEN      PIC 9(10).
           05  STMT-OUT-PAGES-WRITTEN      PIC 9(7).
           05  STMT-OUT-BYTES-WRITTEN      PIC 9(12).
           05  STMT-OUT-DURATION-SEC       PIC 9(5).
