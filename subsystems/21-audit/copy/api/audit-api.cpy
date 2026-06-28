       01  AQF-INPUT.
           05  AQF-DATE-START              PIC 9(8).
           05  AQF-DATE-END                PIC 9(8).
           05  AQF-SUBSYSTEM               PIC X(30).
           05  AQF-ACTION                  PIC X(50).
           05  AQF-SEVERITY                PIC X(1).
               88  AQF-SEV-ANY                      VALUE " ".
               88  AQF-SEV-INFO                     VALUE "I".
               88  AQF-SEV-WARN                     VALUE "W".
               88  AQF-SEV-ERROR                    VALUE "E".
               88  AQF-SEV-CRITICAL                 VALUE "C".
           05  AQF-ACCOUNT-FILTER          PIC X(13).
           05  AQF-MAX-ROWS                PIC 9(5).
           05  AQF-OUTPUT-FORMAT           PIC X(4).
               88  AQF-FMT-TEXT                     VALUE "TEXT".
               88  AQF-FMT-CSV                      VALUE "CSV ".
               88  AQF-FMT-JSON                     VALUE "JSON".
           05  AQF-OUTPUT-FILENAME         PIC X(120).
           05  AQF-OPERATOR-USER           PIC X(30).

       01  AQF-OUTPUT.
           05  AQF-STATUS                  PIC X(2).
               88  AQF-OK                           VALUE "00".
               88  AQF-INVALID-INPUT                VALUE "08".
               88  AQF-IO-FAIL                      VALUE "12".
               88  AQF-FATAL                        VALUE "16".
           05  AQF-OUT-ROW-COUNT           PIC 9(7).
           05  AQF-OUT-QUERY-ID            PIC X(36).
           05  AQF-OUT-DURATION-MS         PIC 9(7).

       01  APR-INPUT.
           05  APR-OPERATOR-USER           PIC X(30).
           05  APR-RETENTION-DAYS          PIC 9(5).
           05  APR-DRY-RUN                 PIC X(1).
               88  APR-DRY-RUN-YES                  VALUE "Y".
               88  APR-DRY-RUN-NO                   VALUE "N".
           05  APR-ENABLE-DETACH           PIC X(1).
               88  APR-DETACH-YES                   VALUE "Y".
               88  APR-DETACH-NO                    VALUE "N".

       01  APR-OUTPUT.
           05  APR-STATUS                  PIC X(2).
               88  APR-OK                           VALUE "00".
               88  APR-INVALID-INPUT                VALUE "08".
               88  APR-FATAL                        VALUE "16".
           05  APR-OUT-CREATED-COUNT       PIC 9(3).
           05  APR-OUT-DETACHED-COUNT      PIC 9(3).
           05  APR-OUT-NEXT-PARTITION      PIC X(20).

       01  ASR-INPUT.
           05  ASR-DATE-START              PIC 9(8).
           05  ASR-DATE-END                PIC 9(8).
           05  ASR-MODE                    PIC X(1).
               88  ASR-MODE-BY-DAY                  VALUE "D".
               88  ASR-MODE-BY-SUBSYSTEM            VALUE "S".
           05  ASR-OUTPUT-FILENAME         PIC X(120).

       01  ASR-OUTPUT.
           05  ASR-STATUS                  PIC X(2).
               88  ASR-OK                           VALUE "00".
               88  ASR-INVALID-INPUT                VALUE "08".
               88  ASR-IO-FAIL                      VALUE "12".
               88  ASR-FATAL                        VALUE "16".
           05  ASR-OUT-GROUP-COUNT         PIC 9(7).
           05  ASR-OUT-TOTAL-ROWS          PIC 9(10).
