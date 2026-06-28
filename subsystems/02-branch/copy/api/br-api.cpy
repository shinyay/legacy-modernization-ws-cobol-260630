       01  BR-INPUT.
           05  BR-IN-CODE          PIC X(3).
           05  BR-IN-REGION        PIC X(20).
           05  BR-IN-OP            PIC X(1).
               88  BR-OP-LOOKUP            VALUE "L".
               88  BR-OP-LIST-REGION       VALUE "R".
               88  BR-OP-LIST-ALL          VALUE "A".

       01  BR-OUTPUT.
           05  BR-OUT-STATUS       PIC 9(2).
               88  BR-STATUS-OK            VALUE 00.
               88  BR-STATUS-NOT-FOUND     VALUE 04.
               88  BR-STATUS-INVALID       VALUE 08.
               88  BR-STATUS-EOF           VALUE 10.
               88  BR-STATUS-FATAL         VALUE 16.
           05  BR-OUT-CODE         PIC X(3).
           05  BR-OUT-NAME-KANJI   PIC X(40).
           05  BR-OUT-NAME-KANA    PIC X(40).
           05  BR-OUT-REGION       PIC X(20).
           05  BR-OUT-STATUS-CODE  PIC X(1).
