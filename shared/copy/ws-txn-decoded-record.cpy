       01  TXN-DECODED-REC.
           05  TXN-REC-TYPE             PIC X(1).
               88  TXN-IS-HEADER                 VALUE "H".
               88  TXN-IS-DETAIL                 VALUE "D".
               88  TXN-IS-TRAILER                VALUE "T".
           05  TXN-BODY                 PIC X(599).

       01  TXN-DECODED-HEADER REDEFINES TXN-DECODED-REC.
           05  TDH-REC-TYPE             PIC X(1).
           05  TDH-BATCH-ID             PIC X(14).
           05  TDH-BUSINESS-DATE        PIC 9(8).
           05  TDH-SOURCE-SYSTEM        PIC X(20).
           05  TDH-EXPECTED-COUNT       PIC 9(10).
           05  TDH-CHECKSUM             PIC X(40).
           05  TDH-FILLER               PIC X(507).

       01  TXN-DECODED-DETAIL REDEFINES TXN-DECODED-REC.
           05  TDD-REC-TYPE             PIC X(1).
           05  TDD-SEQ                  PIC 9(10).
           05  TDD-CATEGORY             PIC X(2).
               88  TDD-CAT-DEPOSIT               VALUE "10".
               88  TDD-CAT-WITHDRAW              VALUE "20".
               88  TDD-CAT-TRANSFER              VALUE "30".
               88  TDD-CAT-WIRE                  VALUE "40".
               88  TDD-CAT-INTEREST              VALUE "50".
               88  TDD-CAT-FEE                   VALUE "60".
               88  TDD-CAT-VALID                 VALUES "10" "20"
                                                        "30" "40"
                                                        "50" "60".
               88  TDD-CAT-REQUIRES-COUNTER      VALUES "30" "40".
           05  TDD-AMOUNT-JPY           PIC 9(15).
           05  TDD-CURRENCY             PIC X(3).
               88  TDD-CCY-JPY                   VALUE "JPY".
           05  TDD-PAYER-ACCT           PIC X(13).
           05  TDD-PAYEE-ACCT           PIC X(13).
           05  TDD-BRANCH-CODE          PIC 9(3).
           05  TDD-PRODUCT-CODE         PIC 9(3).
           05  TDD-DESCRIPTION          PIC X(120).
           05  TDD-SOURCE-BANK          PIC X(4).
           05  TDD-SOURCE-BRANCH        PIC X(3).
           05  TDD-ORIGINAL-SEQ         PIC 9(10).
           05  TDD-FILLER               PIC X(400).

       01  TXN-DECODED-TRAILER REDEFINES TXN-DECODED-REC.
           05  TDT-REC-TYPE             PIC X(1).
           05  TDT-RECORD-COUNT         PIC 9(10).
           05  TDT-AMOUNT-SUM           PIC 9(20).
           05  TDT-CHECKSUM             PIC X(40).
           05  TDT-FILLER               PIC X(529).
