       01  IPST-RUN-INPUT.
           05  IPST-RUN-BATCH-ID            PIC X(14).
           05  IPST-RUN-BUSINESS-DATE       PIC 9(8).
           05  IPST-RUN-SUMMARY-FILENAME    PIC X(80).
           05  IPST-RUN-CHECKPOINT-FILENAME PIC X(80).

       01  IPST-RUN-OUTPUT.
           05  IPST-RUN-STATUS              PIC X(2).
               88  IPST-RUN-OK                       VALUE "00".
               88  IPST-RUN-PARTIAL                  VALUE "04".
               88  IPST-RUN-INVALID-INPUT            VALUE "08".
               88  IPST-RUN-IO-FAIL                  VALUE "12".
               88  IPST-RUN-FATAL                    VALUE "16".
           05  IPST-OUT-ACCOUNTS-AGGREGATED PIC 9(7).
           05  IPST-OUT-ACCOUNTS-POSTED     PIC 9(7).
           05  IPST-OUT-SKIPPED-CLOSED      PIC 9(7).
           05  IPST-OUT-SKIPPED-PRODUCT     PIC 9(7).
           05  IPST-OUT-SKIPPED-ALREADY     PIC 9(7).
           05  IPST-OUT-SKIPPED-HELPER      PIC 9(7).
           05  IPST-OUT-AC-ROWS-CONSUMED    PIC 9(8).
           05  IPST-OUT-TOTAL-POSTED-JPY    PIC S9(15) COMP-3.
           05  IPST-OUT-DURATION-SEC        PIC 9(5).

       01  IPST-REPORT-INPUT.
           05  IPST-RPT-BUSINESS-DATE       PIC 9(8).
           05  IPST-RPT-BATCH-ID            PIC X(14).
           05  IPST-RPT-SUMMARY-FILENAME    PIC X(80).
           05  IPST-RPT-REPORT-FILENAME     PIC X(80).

       01  IPST-REPORT-OUTPUT.
           05  IPST-RPT-STATUS              PIC X(2).
               88  IPST-RPT-OK                       VALUE "00".
               88  IPST-RPT-CONSERVATION-WARN        VALUE "04".
               88  IPST-RPT-INVALID-INPUT            VALUE "08".
               88  IPST-RPT-IO-FAIL                  VALUE "12".
               88  IPST-RPT-FATAL                    VALUE "16".
           05  IPST-RPT-PRODUCTS-REPORTED   PIC 9(2).
           05  IPST-RPT-TOTAL-POSTED        PIC 9(7).
           05  IPST-RPT-TOTAL-POSTED-JPY    PIC S9(15) COMP-3.
           05  IPST-RPT-PT-ROW-COUNT        PIC 9(7).
           05  IPST-RPT-AC-REMAINING        PIC 9(7).
           05  IPST-RPT-ACCRUED-SUM         PIC S9(15) COMP-3.
           05  IPST-RPT-CONSERVATION-PASS   PIC X(1).
           05  IPST-RPT-DURATION-SEC        PIC 9(5).
