       01  WS-INVARIANT-STATE.
           05  WS-I1-RC                 PIC X(1) VALUE "N".
               88  WS-I1-FAIL                    VALUE "Y".
           05  WS-I1-FOUND-FLAG         PIC 9(1) VALUE 0.
           05  WS-I3-RC                 PIC X(1) VALUE "N".
               88  WS-I3-FAIL                    VALUE "Y".
           05  WS-I3-CURRENT-BALANCE    PIC S9(15) COMP-3 VALUE 0.
           05  WS-I3-REMAINING-BALANCE  PIC S9(15) COMP-3 VALUE 0.
           05  WS-I5-RC                 PIC X(1) VALUE "N".
               88  WS-I5-FAIL                    VALUE "Y".
           05  WS-I4-RC                 PIC X(1) VALUE "N".
               88  WS-I4-FAIL                    VALUE "Y".
           05  WS-I4-MAX-CLOSED-DATE    PIC 9(8) VALUE 0.
