       FD  FS-FILE
           RECORD CONTAINS 41 CHARACTERS.
       01  FS-REC.
           05  FS-REC-KEY.
               10  FS-REC-CATEGORY  PIC 9(2).
               10  FS-REC-TIER      PIC 9(2).
               10  FS-REC-EFF-FROM  PIC 9(8).
           05  FS-REC-TIER-MIN     PIC S9(15) COMP-3.
           05  FS-REC-TIER-MAX     PIC S9(15) COMP-3.
           05  FS-REC-AMOUNT       PIC S9(9) COMP-3.
           05  FS-REC-EFF-TO       PIC 9(8).
