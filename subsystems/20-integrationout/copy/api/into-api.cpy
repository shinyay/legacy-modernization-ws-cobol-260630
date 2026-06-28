       01  INTO-INPUT.
           05  INTO-EVENT-TYPE             PIC X(20).
               88  INTO-EVT-TXN-POSTED              VALUE "txn.posted".
               88  INTO-EVT-INTEREST-POSTED         VALUE "interest.posted".
               88  INTO-EVT-AUTODEBIT-FAILED        VALUE "autodebit.failed".
               88  INTO-EVT-BATCH-COMPLETED         VALUE "batch.completed".
               88  INTO-EVT-STATEMENT-GENERATED     VALUE "statement.generated".
           05  INTO-BUSINESS-DATE          PIC 9(8).
           05  INTO-BATCH-ID               PIC X(14).
           05  INTO-TXN-ID                 PIC X(18).
           05  INTO-ACCOUNT                PIC X(13).
           05  INTO-AMOUNT-JPY             PIC S9(15) COMP-3.
           05  INTO-CATEGORY               PIC X(2).
           05  INTO-REASON                 PIC X(10).
           05  INTO-COUNT                  PIC 9(10).
           05  INTO-MODE                   PIC X(1).
               88  INTO-MODE-REAL                   VALUE "R".
               88  INTO-MODE-MOCK                   VALUE "M".

       01  INTO-OUTPUT.
           05  INTO-STATUS                 PIC X(2).
               88  INTO-OK                          VALUE "00".
               88  INTO-RETRY-EXHAUSTED             VALUE "04".
               88  INTO-INVALID-INPUT               VALUE "08".
               88  INTO-BROKER-FAIL                 VALUE "12".
               88  INTO-FATAL                       VALUE "16".
           05  INTO-EVENT-ID               PIC X(36).
           05  INTO-DURATION-MS            PIC 9(7).
           05  INTO-RETRY-COUNT            PIC 9(1).

       01  INTD-INPUT.
           05  INTD-SOURCE-FILENAME        PIC X(120).
           05  INTD-MAX-RECORDS            PIC 9(7).
           05  INTD-MODE                   PIC X(1).
               88  INTD-MODE-REAL                   VALUE "R".
               88  INTD-MODE-MOCK                   VALUE "M".

       01  INTD-OUTPUT.
           05  INTD-STATUS                 PIC X(2).
               88  INTD-OK                          VALUE "00".
               88  INTD-PARTIAL                     VALUE "04".
               88  INTD-INVALID-INPUT               VALUE "08".
               88  INTD-IO-FAIL                     VALUE "12".
               88  INTD-FATAL                       VALUE "16".
           05  INTD-OUT-DRAINED-COUNT      PIC 9(7).
           05  INTD-OUT-FAILED-COUNT       PIC 9(7).
           05  INTD-OUT-DURATION-MS        PIC 9(7).
