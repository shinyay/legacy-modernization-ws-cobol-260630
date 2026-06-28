       FD  IRATE-FILE.
       01  IR-REC.
           05  IR-REC-KEY.
               10  IR-REC-PRODUCT  PIC X(3).
               10  IR-REC-TIER     PIC 9(2).
               10  IR-REC-EFF-FROM PIC 9(8).
           05  IR-REC-TIER-MIN     PIC S9(15) COMP-3.
           05  IR-REC-TIER-MAX     PIC S9(15) COMP-3.
           05  IR-REC-RATE         PIC S9(3)V9(4) COMP-3.
           05  IR-REC-EFF-TO       PIC 9(8).
           05  IR-REC-FILLER       PIC X(8).
