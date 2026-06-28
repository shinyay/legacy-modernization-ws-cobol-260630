       01  IACR-RUN-INPUT.
           05  IACR-RUN-BATCH-ID            PIC X(14).
           05  IACR-RUN-BUSINESS-DATE       PIC 9(8).
           05  IACR-RUN-SUMMARY-FILENAME    PIC X(80).
           05  IACR-RUN-CHECKPOINT-FILENAME PIC X(80).

       01  IACR-RUN-OUTPUT.
           05  IACR-RUN-STATUS              PIC X(2).
               88  IACR-RUN-OK                       VALUE "00".
               88  IACR-RUN-PARTIAL                  VALUE "04".
               88  IACR-RUN-INVALID-INPUT            VALUE "08".
               88  IACR-RUN-IO-FAIL                  VALUE "12".
               88  IACR-RUN-FATAL                    VALUE "16".
           05  IACR-OUT-ACCOUNTS-SCANNED    PIC 9(7).
           05  IACR-OUT-ACCRUALS-INSERTED   PIC 9(7).
           05  IACR-OUT-INELIGIBLE-STATE    PIC 9(7).
           05  IACR-OUT-INELIGIBLE-PROD     PIC 9(7).
           05  IACR-OUT-INELIGIBLE-BALANCE  PIC 9(7).
           05  IACR-OUT-INELIGIBLE-RATE     PIC 9(7).
           05  IACR-OUT-ALREADY-ACCRUED     PIC 9(7).
           05  IACR-OUT-SYSTEM-SKIPPED      PIC 9(7).
           05  IACR-OUT-DURATION-SEC        PIC 9(5).

       01  IACR-REPORT-INPUT.
           05  IACR-RPT-BUSINESS-DATE       PIC 9(8).
           05  IACR-RPT-SUMMARY-FILENAME    PIC X(80).
           05  IACR-RPT-REPORT-FILENAME     PIC X(80).

       01  IACR-REPORT-OUTPUT.
           05  IACR-RPT-STATUS              PIC X(2).
               88  IACR-RPT-OK                       VALUE "00".
               88  IACR-RPT-CONSERVATION-WARN        VALUE "04".
               88  IACR-RPT-INVALID-INPUT            VALUE "08".
               88  IACR-RPT-IO-FAIL                  VALUE "12".
               88  IACR-RPT-FATAL                    VALUE "16".
           05  IACR-RPT-PRODUCTS-REPORTED   PIC 9(2).
           05  IACR-RPT-TOTAL-ACCRUALS      PIC 9(7).
           05  IACR-RPT-TOTAL-ACCRUED-JPY   PIC S9(15) COMP-3.
           05  IACR-RPT-AC-COUNT            PIC 9(7).
           05  IACR-RPT-PT-COUNT            PIC 9(7).
           05  IACR-RPT-GRAND-TOTAL         PIC 9(7).
           05  IACR-RPT-CONSERVATION-PASS   PIC X(1).
           05  IACR-RPT-DURATION-SEC        PIC 9(5).
