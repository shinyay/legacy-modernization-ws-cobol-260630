       FD  IR-SEED-FILE
           RECORD CONTAINS 49 CHARACTERS.
       01  IS-REC.
           05  IS-KEY.
               10  IS-PRODUCT      PIC X(3).
               10  IS-TIER         PIC 9(2).
               10  IS-EFF-FROM     PIC 9(8).
           05  IS-TIER-MIN         PIC S9(15) COMP-3.
           05  IS-TIER-MAX         PIC S9(15) COMP-3.
           05  IS-RATE             PIC S9(3)V9(4) COMP-3.
           05  IS-EFF-TO           PIC 9(8).
           05  IS-FILLER           PIC X(8).
