       01  WS-TXVAL-PER-REC.
           05  WS-FAIL-E001         PIC X(1) VALUE "N".
               88  WS-F-E001-SET            VALUE "Y".
           05  WS-FAIL-E002         PIC X(1) VALUE "N".
               88  WS-F-E002-SET            VALUE "Y".
           05  WS-FAIL-E003         PIC X(1) VALUE "N".
               88  WS-F-E003-SET            VALUE "Y".
           05  WS-FAIL-E007         PIC X(1) VALUE "N".
               88  WS-F-E007-SET            VALUE "Y".
           05  WS-FAIL-E008         PIC X(1) VALUE "N".
               88  WS-F-E008-SET            VALUE "Y".
           05  WS-FAIL-E009         PIC X(1) VALUE "N".
               88  WS-F-E009-SET            VALUE "Y".
           05  WS-FAIL-E010         PIC X(1) VALUE "N".
               88  WS-F-E010-SET            VALUE "Y".
           05  WS-FAIL-E011         PIC X(1) VALUE "N".
               88  WS-F-E011-SET            VALUE "Y".
           05  WS-FAIL-E012         PIC X(1) VALUE "N".
               88  WS-F-E012-SET            VALUE "Y".
           05  WS-FAIL-E013         PIC X(1) VALUE "N".
               88  WS-F-E013-SET            VALUE "Y".
           05  WS-FAIL-E014         PIC X(1) VALUE "N".
               88  WS-F-E014-SET            VALUE "Y".
           05  WS-FAIL-E015         PIC X(1) VALUE "N".
               88  WS-F-E015-SET            VALUE "Y".
           05  WS-FAIL-E016         PIC X(1) VALUE "N".
               88  WS-F-E016-SET            VALUE "Y".
           05  WS-FAIL-E017         PIC X(1) VALUE "N".
               88  WS-F-E017-SET            VALUE "Y".
           05  WS-FAIL-E018         PIC X(1) VALUE "N".
               88  WS-F-E018-SET            VALUE "Y".
           05  WS-FAIL-E019         PIC X(1) VALUE "N".
               88  WS-F-E019-SET            VALUE "Y".
           05  WS-FAIL-E099         PIC X(1) VALUE "N".
               88  WS-F-E099-SET            VALUE "Y".

           05  WS-ANY-FAIL          PIC X(1) VALUE "N".
               88  WS-REC-REJECTED          VALUE "Y".
           05  WS-PRIMARY-CODE      PIC X(4) VALUE SPACES.
           05  WS-REASON-TEXT       PIC X(80) VALUE SPACES.

       01  WS-TXVAL-PER-BATCH.
           05  WS-RUN-PROCESSED     PIC 9(7) VALUE 0.
           05  WS-RUN-VALIDATED     PIC 9(7) VALUE 0.
           05  WS-RUN-REJECTED      PIC 9(7) VALUE 0.

           05  WS-RUN-PRI-E001      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E002      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E003      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E007      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E008      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E009      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E010      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E011      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E012      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E013      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E014      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E015      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E016      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E017      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E018      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E019      PIC 9(7) VALUE 0.
           05  WS-RUN-PRI-E099      PIC 9(7) VALUE 0.

           05  WS-RUN-OCC-E001      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E002      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E003      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E007      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E008      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E009      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E010      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E011      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E012      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E013      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E014      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E015      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E016      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E017      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E018      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E019      PIC 9(7) VALUE 0.
           05  WS-RUN-OCC-E099      PIC 9(7) VALUE 0.
