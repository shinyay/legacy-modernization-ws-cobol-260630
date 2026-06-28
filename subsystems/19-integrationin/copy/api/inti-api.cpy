       01  INTI-INPUT.
           05  INTI-BATCH-ID               PIC X(14).
           05  INTI-BUSINESS-DATE          PIC 9(8).
           05  INTI-INPUT-FILENAME         PIC X(120).
           05  INTI-OUTPUT-FILENAME        PIC X(120).
           05  INTI-REJECT-FILENAME        PIC X(120).
           05  INTI-SENTINEL-FILENAME      PIC X(120).
           05  INTI-REJECT-THRESHOLD-PCT   PIC 9(3).
           05  INTI-REQUIRE-SENTINEL       PIC X(1).
               88  INTI-SENTINEL-YES                VALUE "Y".
               88  INTI-SENTINEL-NO                 VALUE "N".

       01  INTI-OUTPUT.
           05  INTI-STATUS                 PIC X(2).
               88  INTI-OK                          VALUE "00".
               88  INTI-NO-INPUT-READY              VALUE "01".
               88  INTI-PARTIAL                     VALUE "04".
               88  INTI-INVALID-INPUT               VALUE "08".
               88  INTI-IO-FAIL                     VALUE "12".
               88  INTI-FATAL                       VALUE "16".
           05  INTI-OUT-RECORDS-READ       PIC 9(10).
           05  INTI-OUT-DETAILS-DECODED    PIC 9(10).
           05  INTI-OUT-DETAILS-REJECTED   PIC 9(10).
           05  INTI-OUT-REJECT-PCT         PIC 9(3).
           05  INTI-OUT-CHECKSUM-MATCH     PIC X(1).
               88  INTI-CHECKSUM-OK                 VALUE "Y".
               88  INTI-CHECKSUM-MISMATCH           VALUE "N".
           05  INTI-OUT-DURATION-SEC       PIC 9(5).
