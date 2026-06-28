       01  TXSM-SORT-INPUT.
           05  TXSM-SI-BATCH-ID            PIC X(14).
           05  TXSM-SI-BUSINESS-DATE       PIC 9(8).
           05  TXSM-SI-INPUT-FILENAME      PIC X(80).
           05  TXSM-SI-OUTPUT-FILENAME     PIC X(80).
           05  TXSM-SI-CHECKPOINT-FILENAME PIC X(80).

       01  TXSM-SORT-OUTPUT.
           05  TXSM-SO-STATUS              PIC X(2).
               88  TXSM-SO-OK                       VALUE "00".
               88  TXSM-SO-PARTIAL                  VALUE "04".
               88  TXSM-SO-INVALID                  VALUE "08".
               88  TXSM-SO-IO-FAIL                  VALUE "12".
               88  TXSM-SO-FATAL                    VALUE "16".
           05  TXSM-SO-RECORDS-PROCESSED   PIC 9(7).
           05  TXSM-SO-RECORDS-SORTED      PIC 9(7).
           05  TXSM-SO-CTRL-TOTAL-MATCH    PIC X(1).
           05  TXSM-SO-AMOUNT-SUM          PIC 9(20).

       01  TXSM-MERGE-INPUT.
           05  TXSM-MI-BATCH-ID            PIC X(14).
           05  TXSM-MI-BUSINESS-DATE       PIC 9(8).
           05  TXSM-MI-SORTED-FILENAME     PIC X(80).
           05  TXSM-MI-RECON-PREV-FILENAME PIC X(80).
           05  TXSM-MI-READY-FILENAME      PIC X(80).
           05  TXSM-MI-ERROR-FILENAME      PIC X(80).
           05  TXSM-MI-CHECKPOINT-FILENAME PIC X(80).
           05  TXSM-MI-TEMP-FILENAME       PIC X(80).

       01  TXSM-MERGE-OUTPUT.
           05  TXSM-MO-STATUS              PIC X(2).
               88  TXSM-MO-OK                       VALUE "00".
               88  TXSM-MO-PARTIAL                  VALUE "04".
               88  TXSM-MO-INVALID                  VALUE "08".
               88  TXSM-MO-IO-FAIL                  VALUE "12".
               88  TXSM-MO-FATAL                    VALUE "16".
           05  TXSM-MO-RECORDS-SORTED-IN   PIC 9(7).
           05  TXSM-MO-RECORDS-RECON-IN    PIC 9(7).
           05  TXSM-MO-RECORDS-MERGED-OUT  PIC 9(7).
           05  TXSM-MO-DUPLICATE-RECORDS   PIC 9(5).
           05  TXSM-MO-DUPLICATE-PAIRS     PIC 9(5).
           05  TXSM-MO-SORT-VIOLATIONS     PIC 9(5).
           05  TXSM-MO-RECON-PRESENT-FLAG  PIC X(1).
           05  TXSM-MO-AMOUNT-SUM          PIC 9(20).

       01  TXSM-REPORT-INPUT.
           05  TXSM-RP-BATCH-ID            PIC X(14).
           05  TXSM-RP-SUMMARY-FILENAME    PIC X(80).
           05  TXSM-RP-REPORT-FILENAME     PIC X(80).

       01  TXSM-REPORT-OUTPUT.
           05  TXSM-RP-STATUS              PIC X(2).
               88  TXSM-RP-OK                       VALUE "00".
               88  TXSM-RP-PARTIAL                  VALUE "04".
               88  TXSM-RP-IO-FAIL                  VALUE "12".
               88  TXSM-RP-FATAL                    VALUE "16".
           05  TXSM-RP-LINES-WRITTEN       PIC 9(5).
           05  TXSM-RP-CONSERVATION-OK     PIC X(1).
