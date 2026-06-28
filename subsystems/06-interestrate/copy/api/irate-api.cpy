       01  IRATE-INPUT.
           05  IR-IN-PRODUCT       PIC X(3).
           05  IR-IN-TIER          PIC 9(2).
           05  IR-IN-EFFECTIVE     PIC 9(8).
       01  IRATE-OUTPUT.
           05  IR-OUT-STATUS       PIC 9(2).
               88  IR-OK                VALUE 00.
               88  IR-NOT-FOUND         VALUE 04.
               88  IR-FATAL             VALUE 16.
           05  IR-OUT-RATE-MICRO   PIC 9(7).
           05  IR-OUT-EFF-FROM     PIC 9(8).
           05  IR-OUT-EFF-TO       PIC 9(8).
