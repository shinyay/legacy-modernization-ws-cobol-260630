       01  FS-INPUT.
           05  FS-IN-CATEGORY      PIC 9(2).
               88  FS-CAT-DEPOSIT          VALUE 10.
               88  FS-CAT-WITHDRAW         VALUE 20.
               88  FS-CAT-TRANSFER         VALUE 30.
               88  FS-CAT-WIRE             VALUE 40.
           05  FS-IN-TIER          PIC 9(2).
           05  FS-IN-EFFECTIVE     PIC 9(8).
       01  FS-OUTPUT.
           05  FS-OUT-STATUS       PIC 9(2).
               88  FS-OK                    VALUE 00.
               88  FS-NOT-FOUND             VALUE 04.
               88  FS-FATAL                 VALUE 16.
           05  FS-OUT-FEE-JPY      PIC S9(9).
           05  FS-OUT-EFF-TO       PIC 9(8).
