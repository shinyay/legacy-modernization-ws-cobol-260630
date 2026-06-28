       01  AD-RUN-INPUT.
           05  AD-RUN-BATCH-ID            PIC X(14).
           05  AD-RUN-BUSINESS-DATE       PIC 9(8).
           05  AD-RUN-FAILED-FILENAME     PIC X(80).
           05  AD-RUN-CHECKPOINT-FILENAME PIC X(80).
           05  AD-RUN-SUMMARY-FILENAME    PIC X(80).

       01  AD-RUN-OUTPUT.
           05  AD-RUN-STATUS              PIC X(2).
               88  AD-RUN-OK                       VALUE "00".
               88  AD-RUN-PARTIAL                  VALUE "04".
               88  AD-RUN-INVALID-INPUT            VALUE "08".
               88  AD-RUN-IO-FAIL                  VALUE "12".
               88  AD-RUN-FATAL                    VALUE "16".
           05  AD-OUT-INSTRUCTIONS-DUE    PIC 9(7).
           05  AD-OUT-INSTRUCTIONS-POSTED PIC 9(7).
           05  AD-OUT-FAILED-NF           PIC 9(7).
           05  AD-OUT-FAILED-CL           PIC 9(7).
           05  AD-OUT-FAILED-SU           PIC 9(7).
           05  AD-OUT-SKIPPED-ALREADY     PIC 9(7).
           05  AD-OUT-SKIPPED-HELPER      PIC 9(7).
           05  AD-OUT-AUTO-SUSPENDED      PIC 9(7).
           05  AD-OUT-AUTO-TERMINATED     PIC 9(7).
           05  AD-OUT-TOTAL-DEBITED-JPY   PIC S9(15) COMP-3.
           05  AD-OUT-DURATION-SEC        PIC 9(5).

       01  AD-REPORT-INPUT.
           05  AD-RPT-BUSINESS-DATE       PIC 9(8).
           05  AD-RPT-BATCH-ID            PIC X(14).
           05  AD-RPT-SUMMARY-FILENAME    PIC X(80).
           05  AD-RPT-REPORT-FILENAME     PIC X(80).
           05  AD-RPT-FAILED-FILENAME     PIC X(80).

       01  AD-REPORT-OUTPUT.
           05  AD-RPT-STATUS              PIC X(2).
               88  AD-RPT-OK                       VALUE "00".
               88  AD-RPT-CONSERVATION-WARN        VALUE "04".
               88  AD-RPT-INVALID-INPUT            VALUE "08".
               88  AD-RPT-IO-FAIL                  VALUE "12".
               88  AD-RPT-FATAL                    VALUE "16".
           05  AD-RPT-TOTAL-INSTRUCTIONS  PIC 9(7).
           05  AD-RPT-TOTAL-OK-JPY        PIC S9(15) COMP-3.
           05  AD-RPT-TOTAL-FAILED-COUNT  PIC 9(7).
           05  AD-RPT-SUSPENDED-COUNT     PIC 9(7).
           05  AD-RPT-PG-PT-COUNT         PIC 9(7).
           05  AD-RPT-FILE-FAILED-COUNT   PIC 9(7).
           05  AD-RPT-CONSERVATION-PASS   PIC X(1).
           05  AD-RPT-DURATION-SEC        PIC 9(5).
