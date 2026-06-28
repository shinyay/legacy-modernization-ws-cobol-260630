       01  EBCDIC-REC.
           05  ER-TYPE                 PIC X(1).
           05  ER-BODY                 PIC X(799).

       01  EBCDIC-HEADER REDEFINES EBCDIC-REC.
           05  EH-TYPE                 PIC X(1).
           05  EH-BATCH-ID             PIC X(14).
           05  EH-BUSINESS-DATE        PIC 9(8).
           05  EH-SOURCE-SYSTEM        PIC X(20).
           05  EH-EXPECTED-COUNT       PIC 9(10).
           05  EH-CHECKSUM             PIC X(40).
           05  FILLER                  PIC X(707).

       01  EBCDIC-DETAIL REDEFINES EBCDIC-REC.
           05  ED-TYPE                 PIC X(1).
           05  ED-SOURCE-BANK          PIC 9(4).
           05  ED-SOURCE-BRANCH        PIC 9(3).
           05  ED-CATEGORY             PIC 9(2).
           05  ED-AMOUNT-JPY           PIC S9(15) COMP-3.
           05  ED-PAYER-ACCT           PIC X(13).
           05  ED-PAYEE-ACCT           PIC X(13).
           05  ED-DESCRIPTION          PIC X(120).
           05  ED-ORIGINAL-SEQ         PIC 9(10).
           05  ED-BRANCH-CODE          PIC 9(3).
           05  ED-PRODUCT-CODE         PIC 9(3).
           05  ED-RESERVED             PIC X(595).

       01  EBCDIC-TRAILER REDEFINES EBCDIC-REC.
           05  ET-TYPE                 PIC X(1).
           05  ET-RECORD-COUNT         PIC 9(10).
           05  ET-AMOUNT-SUM           PIC 9(20).
           05  ET-CHECKSUM             PIC X(40).
           05  FILLER                  PIC X(729).
