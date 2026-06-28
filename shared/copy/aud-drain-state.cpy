       01  WS-DRAIN-CMD             PIC X(255) VALUE SPACES.
       01  WS-DRAIN-ENV-VAL         PIC X(255) VALUE SPACES.
       01  WS-DRAIN-RAW-RC          PIC S9(9) COMP-5 VALUE 0.
       01  WS-DRAIN-EXIT            PIC 9(4)  VALUE 0.
       01  WS-DRAIN-DEFAULT-CMD     PIC X(60)
           VALUE "/workspace/shared/util/aud-drain/bin/aud-drain-main".
