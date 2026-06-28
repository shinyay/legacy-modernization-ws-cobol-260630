       01  OPB-INPUT.
           05  OPB-BATCH-ID                PIC X(14).
           05  OPB-BUSINESS-DATE           PIC 9(8).
           05  OPB-DRY-RUN                 PIC X(1).
               88  OPB-DRY-RUN-YES                  VALUE "Y".
               88  OPB-DRY-RUN-NO                   VALUE "N".

       01  OPB-OUTPUT.
           05  OPB-STATUS                  PIC X(2).
               88  OPB-OK                           VALUE "00".
               88  OPB-HALTED                       VALUE "04".
               88  OPB-INVALID-INPUT                VALUE "08".
               88  OPB-FLOCK-CONFLICT               VALUE "02".
               88  OPB-FATAL                        VALUE "16".
           05  OPB-OUT-LAST-STEP           PIC X(20).
           05  OPB-OUT-STEPS-RUN           PIC 9(2).
           05  OPB-OUT-FINALIZED-COUNT     PIC 9(7).
           05  OPB-OUT-DURATION-SEC        PIC 9(5).

       01  OPF-INPUT.
           05  OPF-BATCH-ID                PIC X(14).
           05  OPF-BUSINESS-DATE           PIC 9(8).
           05  OPF-CHUNK-SIZE              PIC 9(7).

       01  OPF-OUTPUT.
           05  OPF-STATUS                  PIC X(2).
               88  OPF-OK                           VALUE "00".
               88  OPF-INVALID-INPUT                VALUE "08".
               88  OPF-IO-FAIL                      VALUE "12".
               88  OPF-FATAL                        VALUE "16".
           05  OPF-OUT-FINALIZED-COUNT     PIC 9(7).
           05  OPF-OUT-CHUNKS-RUN          PIC 9(4).

       01  OPR-INPUT.
           05  OPR-OPERATOR-USER           PIC X(30).
           05  OPR-RETENTION-DAYS          PIC 9(5).
           05  OPR-DRY-RUN                 PIC X(1).
           05  OPR-ENABLE-DETACH           PIC X(1).

       01  OPR-OUTPUT.
           05  OPR-STATUS                  PIC X(2).
               88  OPR-OK                           VALUE "00".
               88  OPR-FATAL                        VALUE "16".
           05  OPR-OUT-CREATED-COUNT       PIC 9(3).
           05  OPR-OUT-DETACHED-COUNT      PIC 9(3).
           05  OPR-OUT-NEXT-PARTITION      PIC X(20).

       01  OPD-INPUT.
           05  OPD-SOURCE-FILENAME         PIC X(120).
           05  OPD-MAX-RECORDS             PIC 9(7).
           05  OPD-MODE                    PIC X(1).
               88  OPD-MODE-MOCK                    VALUE "M".
               88  OPD-MODE-REAL                    VALUE "R".

       01  OPD-OUTPUT.
           05  OPD-STATUS                  PIC X(2).
               88  OPD-OK                           VALUE "00".
               88  OPD-PARTIAL                      VALUE "04".
               88  OPD-FATAL                        VALUE "16".
           05  OPD-OUT-DRAINED-COUNT       PIC 9(7).
           05  OPD-OUT-FAILED-COUNT        PIC 9(7).
