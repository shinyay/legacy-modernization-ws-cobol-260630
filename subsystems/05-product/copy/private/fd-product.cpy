       FD  PRODUCT-FILE.
       01  PRD-REC.
           05  PRD-REC-CODE        PIC X(3).
           05  PRD-REC-NAME-KANJI  PIC X(40).
           05  PRD-REC-NAME-KANA   PIC X(40).
           05  PRD-REC-TYPE        PIC X(1).
           05  PRD-REC-INTEREST    PIC X(1).
           05  PRD-REC-OVD         PIC X(1).
           05  PRD-REC-MIN-BAL     PIC S9(15) COMP-3.
           05  PRD-REC-TERM-DAYS   PIC 9(4).
           05  PRD-REC-EFF-FROM    PIC 9(8).
           05  PRD-REC-EFF-TO      PIC 9(8).
           05  PRD-REC-FILLER      PIC X(16).
