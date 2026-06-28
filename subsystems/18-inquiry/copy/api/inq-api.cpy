       01  INQ-INPUT.
           05  INQ-MODE                    PIC X(1).
               88  INQ-MODE-SCREEN              VALUE "S".
               88  INQ-MODE-NOSCREEN            VALUE "N".
           05  INQ-OPERATOR-USER           PIC X(32).
           05  INQ-INITIAL-ACTION          PIC X(1).
           05  INQ-INITIAL-PARAM           PIC X(50).

       01  INQ-OUTPUT.
           05  INQ-STATUS                  PIC X(2).
               88  INQ-OK                       VALUE "00".
               88  INQ-INVALID-INPUT            VALUE "08".
               88  INQ-IO-FAIL                  VALUE "12".
               88  INQ-FATAL                    VALUE "16".
           05  INQ-SESSION-DURATION-SEC    PIC 9(7).
           05  INQ-QUERIES-EXECUTED        PIC 9(5).
