       FD  PRD-SEED-FILE.
       01  PS-REC.
           05  PS-CODE         PIC X(3).
           05  PS-NAME-KANJI   PIC X(40).
           05  PS-NAME-KANA    PIC X(40).
           05  PS-TYPE         PIC X(1).
           05  PS-INTEREST     PIC X(1).
           05  PS-OVD          PIC X(1).
           05  PS-MIN-BAL      PIC S9(15) COMP-3.
           05  PS-TERM-DAYS    PIC 9(4).
           05  PS-EFF-FROM     PIC 9(8).
           05  PS-EFF-TO       PIC 9(8).
           05  PS-FILLER       PIC X(16).
