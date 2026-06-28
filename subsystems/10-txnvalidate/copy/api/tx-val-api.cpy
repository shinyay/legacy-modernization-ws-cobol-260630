       01  TXVAL-BATCH-INPUT.
           05  TXVAL-IN-BATCH-ID            PIC X(14).
           05  TXVAL-IN-BUSINESS-DATE       PIC 9(8).
           05  TXVAL-IN-INPUT-FILENAME      PIC X(80).
           05  TXVAL-IN-VALID-FILENAME      PIC X(80).
           05  TXVAL-IN-ERROR-FILENAME      PIC X(80).
           05  TXVAL-IN-CHECKPOINT-FILENAME PIC X(80).

       01  TXVAL-BATCH-OUTPUT.
           05  TXVAL-BATCH-STATUS           PIC X(2).
               88  TXVAL-OK                          VALUE "00".
               88  TXVAL-PARTIAL-REJECT              VALUE "04".
               88  TXVAL-INVALID-INPUT               VALUE "08".
               88  TXVAL-IO-FAIL                     VALUE "12".
               88  TXVAL-FATAL                       VALUE "16".
           05  TXVAL-OUT-PROCESSED          PIC 9(7).
           05  TXVAL-OUT-VALIDATED          PIC 9(7).
           05  TXVAL-OUT-REJECTED           PIC 9(7).
           05  TXVAL-OUT-PRI-E001           PIC 9(7).
           05  TXVAL-OUT-PRI-E002           PIC 9(7).
           05  TXVAL-OUT-PRI-E003           PIC 9(7).
           05  TXVAL-OUT-PRI-E007           PIC 9(7).
           05  TXVAL-OUT-PRI-E008           PIC 9(7).
           05  TXVAL-OUT-PRI-E009           PIC 9(7).
           05  TXVAL-OUT-PRI-E010           PIC 9(7).
           05  TXVAL-OUT-PRI-E011           PIC 9(7).
           05  TXVAL-OUT-PRI-E012           PIC 9(7).
           05  TXVAL-OUT-PRI-E013           PIC 9(7).
           05  TXVAL-OUT-PRI-E014           PIC 9(7).
           05  TXVAL-OUT-PRI-E015           PIC 9(7).
           05  TXVAL-OUT-PRI-E016           PIC 9(7).
           05  TXVAL-OUT-PRI-E017           PIC 9(7).
           05  TXVAL-OUT-PRI-E018           PIC 9(7).
           05  TXVAL-OUT-PRI-E019           PIC 9(7).
           05  TXVAL-OUT-PRI-E099           PIC 9(7).
           05  TXVAL-OUT-OCC-E001           PIC 9(7).
           05  TXVAL-OUT-OCC-E002           PIC 9(7).
           05  TXVAL-OUT-OCC-E003           PIC 9(7).
           05  TXVAL-OUT-OCC-E007           PIC 9(7).
           05  TXVAL-OUT-OCC-E008           PIC 9(7).
           05  TXVAL-OUT-OCC-E009           PIC 9(7).
           05  TXVAL-OUT-OCC-E010           PIC 9(7).
           05  TXVAL-OUT-OCC-E011           PIC 9(7).
           05  TXVAL-OUT-OCC-E012           PIC 9(7).
           05  TXVAL-OUT-OCC-E013           PIC 9(7).
           05  TXVAL-OUT-OCC-E014           PIC 9(7).
           05  TXVAL-OUT-OCC-E015           PIC 9(7).
           05  TXVAL-OUT-OCC-E016           PIC 9(7).
           05  TXVAL-OUT-OCC-E017           PIC 9(7).
           05  TXVAL-OUT-OCC-E018           PIC 9(7).
           05  TXVAL-OUT-OCC-E019           PIC 9(7).
           05  TXVAL-OUT-OCC-E099           PIC 9(7).

       01  TXVAL-CKPT-RECOVER-INPUT.
           05  TXVAL-CR-IN-FILENAME         PIC X(80).

       01  TXVAL-CKPT-RECOVER-OUTPUT.
           05  TXVAL-CR-STATUS              PIC X(2).
               88  TXVAL-CR-FOUND                    VALUE "00".
               88  TXVAL-CR-NO-CHECKPOINT            VALUE "04".
               88  TXVAL-CR-CORRUPT                  VALUE "12".
               88  TXVAL-CR-FATAL                    VALUE "16".
           05  TXVAL-CR-OUT-LAST-SEQ        PIC 9(10).

       01  TXVAL-REPORT-INPUT.
           05  TXVAL-RP-IN-BATCH-ID         PIC X(14).
           05  TXVAL-RP-IN-SUMMARY-FILENAME PIC X(80).
           05  TXVAL-RP-IN-REPORT-FILENAME  PIC X(80).

       01  TXVAL-REPORT-OUTPUT.
           05  TXVAL-RP-STATUS              PIC X(2).
               88  TXVAL-RP-OK                       VALUE "00".
               88  TXVAL-RP-EMPTY                    VALUE "04".
               88  TXVAL-RP-IO-FAIL                  VALUE "12".
               88  TXVAL-RP-FATAL                    VALUE "16".
           05  TXVAL-RP-OUT-LINES-WRITTEN   PIC 9(5).
