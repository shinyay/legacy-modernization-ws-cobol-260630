       01  WS-DATE-VALIDATE-WORK.
           05  WS-DV-INPUT-DATE        PIC 9(8).
           05  WS-DV-INPUT-SUBFIELDS REDEFINES WS-DV-INPUT-DATE.
               10  WS-DV-IN-YYYY       PIC 9(4).
               10  WS-DV-IN-MM         PIC 9(2).
               10  WS-DV-IN-DD         PIC 9(2).
           05  WS-DV-OUTPUT-DATE       PIC 9(8).
           05  WS-DV-RC                PIC 9       VALUE ZERO.
           05  WS-DV-YYYY              PIC 9(4).
           05  WS-DV-MM                PIC 9(2).
           05  WS-DV-DD                PIC 9(2).
           05  WS-DV-LEAP-FLAG         PIC X       VALUE 'N'.
               88  WS-DV-IS-LEAP                    VALUE 'Y'.
               88  WS-DV-NOT-LEAP                   VALUE 'N'.
           05  WS-DV-MONTH-DAYS-TABLE.
               10  FILLER              PIC 9(2) VALUE 31.
               10  FILLER              PIC 9(2) VALUE 28.
               10  FILLER              PIC 9(2) VALUE 31.
               10  FILLER              PIC 9(2) VALUE 30.
               10  FILLER              PIC 9(2) VALUE 31.
               10  FILLER              PIC 9(2) VALUE 30.
               10  FILLER              PIC 9(2) VALUE 31.
               10  FILLER              PIC 9(2) VALUE 31.
               10  FILLER              PIC 9(2) VALUE 30.
               10  FILLER              PIC 9(2) VALUE 31.
               10  FILLER              PIC 9(2) VALUE 30.
               10  FILLER              PIC 9(2) VALUE 31.
           05  WS-DV-MONTH-DAYS REDEFINES WS-DV-MONTH-DAYS-TABLE.
               10  WS-DV-DAYS-OF-MONTH PIC 9(2) OCCURS 12 TIMES.
           05  WS-DV-EXPECTED-DAYS     PIC 9(2).
