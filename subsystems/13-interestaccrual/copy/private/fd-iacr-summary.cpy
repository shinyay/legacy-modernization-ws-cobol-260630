       FD  IACR-SUMMARY-FILE.
       01  IACR-SUMMARY-REC               PIC X(80).

       01  IACR-SUMMARY-ROW.
           05  IS-ROW-TYPE                PIC X(1).
               88  IS-PER-PRODUCT                 VALUE "P".
               88  IS-GRAND-TOTAL                 VALUE "G".
               88  IS-COUNTERS                    VALUE "C".
           05  IS-PRODUCT-CODE            PIC X(3).
           05  IS-COUNT                   PIC 9(7).
           05  IS-TOTAL-JPY               PIC 9(15).
           05  IS-AVG-RATE-MICRO          PIC 9(7).
           05  IS-FILLER                  PIC X(47).
