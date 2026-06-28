       01  WS-CAL-CACHE-HDR.
           05  WS-CAL-CACHE-LOADED      PIC X(1) VALUE "N".
               88  WS-CAL-CACHE-OK              VALUE "Y".
           05  WS-CAL-CACHE-COUNT       PIC 9(5) VALUE 0.
           05  WS-CAL-START-DATE        PIC 9(8) VALUE 20260101.

       01  WS-CAL-CACHE.
           05  WS-CAL-ENTRY OCCURS 1830 TIMES INDEXED BY WS-CAL-IDX.
               10  WS-CAL-E-DATE        PIC 9(8).
               10  WS-CAL-E-DAY-TYPE    PIC X(1).
               10  WS-CAL-E-VALID-FLAG  PIC X(1).

       01  WS-BR-CACHE-HDR.
           05  WS-BR-CACHE-LOADED       PIC X(1) VALUE "N".
               88  WS-BR-CACHE-OK               VALUE "Y".
           05  WS-BR-CACHE-COUNT        PIC 9(3) VALUE 0.

       01  WS-BR-CACHE.
           05  WS-BR-ENTRY OCCURS 50 TIMES INDEXED BY WS-BR-IDX.
               10  WS-BR-E-CODE         PIC X(3).
               10  WS-BR-E-STATUS       PIC X(1).
               10  WS-BR-E-VALID-FLAG   PIC X(1).

       01  WS-PROD-CACHE-HDR.
           05  WS-PROD-CACHE-LOADED     PIC X(1) VALUE "N".
               88  WS-PROD-CACHE-OK             VALUE "Y".
           05  WS-PROD-CACHE-COUNT      PIC 9(3) VALUE 0.

       01  WS-PROD-CACHE.
           05  WS-PROD-ENTRY OCCURS 20 TIMES INDEXED BY WS-PROD-IDX.
               10  WS-PROD-E-CODE       PIC X(3).
               10  WS-PROD-E-TYPE       PIC X(1).
               10  WS-PROD-E-EFF-FROM   PIC 9(8).
               10  WS-PROD-E-EFF-TO     PIC 9(8).
               10  WS-PROD-E-VALID-FLAG PIC X(1).

       01  WS-KNOWN-BR-CODES.
           05  FILLER PIC X(3) VALUE "001".
           05  FILLER PIC X(3) VALUE "101".
           05  FILLER PIC X(3) VALUE "102".
           05  FILLER PIC X(3) VALUE "103".
           05  FILLER PIC X(3) VALUE "201".
           05  FILLER PIC X(3) VALUE "202".
           05  FILLER PIC X(3) VALUE "203".
           05  FILLER PIC X(3) VALUE "301".
           05  FILLER PIC X(3) VALUE "302".
           05  FILLER PIC X(3) VALUE "303".
       01  WS-KNOWN-BR-TABLE REDEFINES WS-KNOWN-BR-CODES.
           05  WS-KNOWN-BR OCCURS 10 TIMES PIC X(3).

       01  WS-KNOWN-PROD-CODES.
           05  FILLER PIC X(3) VALUE "001".
           05  FILLER PIC X(3) VALUE "002".
           05  FILLER PIC X(3) VALUE "003".
       01  WS-KNOWN-PROD-TABLE REDEFINES WS-KNOWN-PROD-CODES.
           05  WS-KNOWN-PROD OCCURS 3 TIMES PIC X(3).
