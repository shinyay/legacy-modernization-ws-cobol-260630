       01  FEE-CHARGE-INPUT.
           05  FEE-CHARGE-BATCH-ID         PIC X(14).
           05  FEE-CHARGE-BUSINESS-DATE    PIC 9(8).
           05  FEE-CHARGE-SUMMARY-FILENAME PIC X(80).

       01  FEE-CHARGE-OUTPUT.
           05  FEE-CHARGE-STATUS           PIC X(2).
               88  FEE-CHARGE-OK                    VALUE "00".
               88  FEE-CHARGE-PARTIAL               VALUE "04".
               88  FEE-CHARGE-INVALID-INPUT         VALUE "08".
               88  FEE-CHARGE-IO-FAIL               VALUE "12".
               88  FEE-CHARGE-FATAL                 VALUE "16".
           05  FEE-OUT-TXNS-SCANNED        PIC 9(7).
           05  FEE-OUT-CHARGES-POSTED      PIC 9(7).
           05  FEE-OUT-SKIPPED-NO-FEE      PIC 9(7).
           05  FEE-OUT-SKIPPED-CLOSED      PIC 9(7).
           05  FEE-OUT-SKIPPED-NSF         PIC 9(7).
           05  FEE-OUT-SKIPPED-ALREADY     PIC 9(7).
           05  FEE-OUT-SKIPPED-HELPER      PIC 9(7).
           05  FEE-OUT-TOTAL-FEE-JPY       PIC S9(15) COMP-3.
           05  FEE-OUT-DURATION-SEC        PIC 9(5).

       01  FEE-REPORT-INPUT.
           05  FEE-RPT-BUSINESS-DATE       PIC 9(8).
           05  FEE-RPT-BATCH-ID            PIC X(14).
           05  FEE-RPT-SUMMARY-FILENAME    PIC X(80).
           05  FEE-RPT-REPORT-FILENAME     PIC X(80).

       01  FEE-REPORT-OUTPUT.
           05  FEE-RPT-STATUS              PIC X(2).
               88  FEE-RPT-OK                       VALUE "00".
               88  FEE-RPT-CONSERVATION-WARN        VALUE "04".
               88  FEE-RPT-INVALID-INPUT            VALUE "08".
               88  FEE-RPT-IO-FAIL                  VALUE "12".
               88  FEE-RPT-FATAL                    VALUE "16".
           05  FEE-RPT-TOTAL-CHARGES       PIC 9(7).
           05  FEE-RPT-TOTAL-FEE-JPY       PIC S9(15) COMP-3.
           05  FEE-RPT-FEE-REVENUE-BAL     PIC S9(15) COMP-3.
           05  FEE-RPT-CONSERVATION-PASS   PIC X(1).
           05  FEE-RPT-DURATION-SEC        PIC 9(5).
