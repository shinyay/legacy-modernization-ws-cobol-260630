       01  PROD-INPUT.
           05  PRD-IN-CODE         PIC X(3).
       01  PROD-OUTPUT.
           05  PRD-OUT-STATUS      PIC 9(2).
               88  PRD-STATUS-OK            VALUE 00.
               88  PRD-STATUS-NOT-FOUND     VALUE 04.
               88  PRD-STATUS-FATAL         VALUE 16.
           05  PRD-OUT-CODE        PIC X(3).
           05  PRD-OUT-NAME        PIC X(40).
           05  PRD-OUT-TYPE        PIC X(1).
               88  PRD-TYPE-SAVINGS         VALUE "S".
               88  PRD-TYPE-CHECKING        VALUE "C".
               88  PRD-TYPE-TIME-DEPOSIT    VALUE "T".
           05  PRD-OUT-INTEREST-TYPE PIC X(1).
           05  PRD-OUT-ALLOW-OVD   PIC X(1).
           05  PRD-OUT-TERM-DAYS   PIC 9(4).
           05  PRD-OUT-EFF-FROM    PIC 9(8).
           05  PRD-OUT-EFF-TO      PIC 9(8).
