       01  TXPOST-RUN-INPUT.
           05  TXPR-IN-BATCH-ID             PIC X(14).
           05  TXPR-IN-BUSINESS-DATE        PIC 9(8).
           05  TXPR-IN-READY-FILENAME       PIC X(80).
           05  TXPR-IN-ERROR-FILENAME       PIC X(80).
           05  TXPR-IN-RECON-DEFER-FILENAME PIC X(80).
           05  TXPR-IN-CHECKPOINT-FILENAME  PIC X(80).
           05  TXPR-IN-DORMANCY-FILENAME    PIC X(80).

       01  TXPOST-RUN-OUTPUT.
           05  TXPR-STATUS                  PIC X(2).
               88  TXPR-OK                          VALUE "00".
               88  TXPR-PARTIAL-RECON               VALUE "04".
               88  TXPR-INVALID                     VALUE "08".
               88  TXPR-IO-FAIL                     VALUE "12".
               88  TXPR-FATAL                       VALUE "16".

           05  TXPR-RECORDS-READ            PIC 9(7).
           05  TXPR-RECORDS-ATTEMPTED       PIC 9(7).
           05  TXPR-RECORDS-POSTED          PIC 9(7).
           05  TXPR-ALREADY-POSTED-SKIPPED  PIC 9(7).
           05  TXPR-HARD-REJECTED           PIC 9(7).
           05  TXPR-RECON-DEFERRED          PIC 9(7).
           05  TXPR-IN-DOUBT-RESOLVED       PIC 9(7).
           05  TXPR-DORMANCY-DEFERRED       PIC 9(7).

           05  TXPR-REASON-E004             PIC 9(7).
           05  TXPR-REASON-E005             PIC 9(7).
           05  TXPR-REASON-E006             PIC 9(7).
           05  TXPR-REASON-E020             PIC 9(7).
           05  TXPR-REASON-E021             PIC 9(7).
           05  TXPR-REASON-E022             PIC 9(7).
           05  TXPR-REASON-E023             PIC 9(7).
           05  TXPR-REASON-E024             PIC 9(7).
           05  TXPR-REASON-E025             PIC 9(7).
           05  TXPR-REASON-E026             PIC 9(7).

           05  TXPR-DURATION-SEC            PIC 9(5).

       01  TXPOST-REVERSE-INPUT.
           05  TXPV-ORIG-TXN-ID             PIC X(18).
           05  TXPV-REVERSAL-REASON         PIC X(80).
           05  TXPV-OPERATOR-ID             PIC X(20).

       01  TXPOST-REVERSE-OUTPUT.
           05  TXPV-STATUS                  PIC X(2).
               88  TXPV-OK                          VALUE "00".
               88  TXPV-ORIG-NOT-FOUND              VALUE "04".
               88  TXPV-INVALID                     VALUE "08".
               88  TXPV-IO-FAIL                     VALUE "12".
               88  TXPV-FATAL                       VALUE "16".
           05  TXPV-NEW-RV-TXN-ID           PIC X(18).
           05  TXPV-IN-DOUBT-RESOLVED       PIC X(1).

       01  TXPOST-REPORT-INPUT.
           05  TXPS-BATCH-ID                PIC X(14).
           05  TXPS-SUMMARY-FILENAME        PIC X(80).
           05  TXPS-REPORT-FILENAME         PIC X(80).

       01  TXPOST-REPORT-OUTPUT.
           05  TXPS-STATUS                  PIC X(2).
               88  TXPS-OK                          VALUE "00".
               88  TXPS-PARTIAL                     VALUE "04".
               88  TXPS-IO-FAIL                     VALUE "12".
               88  TXPS-FATAL                       VALUE "16".
           05  TXPS-LINES-WRITTEN           PIC 9(5).
           05  TXPS-CONSERVATION-OK         PIC X(1).
