       IDENTIFICATION DIVISION.
       PROGRAM-ID. SHARED-LOG.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT LOG-FILE ASSIGN TO SL-FILE-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS SL-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  LOG-FILE.
       01  LOG-REC                       PIC X(700).

       WORKING-STORAGE SECTION.
       01  SL-INIT-FLAG                  PIC X VALUE 'N'.
           88  SL-INITIALIZED              VALUE 'Y'.
           88  SL-NOT-INITIALIZED          VALUE 'N'.

       01  SL-FILE-OPEN                  PIC X VALUE 'N'.
           88  SL-FILE-IS-OPEN              VALUE 'Y'.

       01  SL-FALLBACK-MODE              PIC X VALUE 'N'.
           88  SL-IN-FALLBACK               VALUE 'Y'.

       01  SL-FILE-STATUS                PIC X(2).
       01  SL-FILE-PATH                  PIC X(200).
       01  SL-FILE-PATH-LEN              PIC 9(3).

       01  SL-MIN-LEVEL                  PIC X(5) VALUE 'INFO '.
       01  SL-ENV-VAL                    PIC X(20).
       01  SL-EMIT-FLAG                  PIC X.
           88  SL-SHOULD-EMIT               VALUE 'Y'.
           88  SL-SHOULD-SKIP               VALUE 'N'.

       01  SL-CD                         PIC X(21).
       01  SL-CD-PARTS REDEFINES SL-CD.
           05  SL-CD-YYYY                PIC 9(4).
           05  SL-CD-MM                  PIC 9(2).
           05  SL-CD-DD                  PIC 9(2).
           05  SL-CD-HH                  PIC 9(2).
           05  SL-CD-MI                  PIC 9(2).
           05  SL-CD-SS                  PIC 9(2).
           05  SL-CD-MS                  PIC 9(2).
           05  SL-CD-TZSIGN              PIC X.
           05  SL-CD-TZHH                PIC 9(2).
           05  SL-CD-TZMM                PIC 9(2).
       01  SL-CURRENT-DATE-RAW           PIC X(21).

       01  SL-TS                         PIC X(29).
       01  SL-DATE-SUFFIX                PIC X(30).
       01  SL-PID                        PIC 9(7) VALUE ZERO.
       01  SL-PID-DISP                   PIC ZZZZZZ9.
       01  SL-LOG-DIR                    PIC X(40) VALUE "/data/logs".

       01  SL-FORMATTED-MSG              PIC X(700).
       01  SL-LOGGER-CMD                 PIC X(700).
       01  SL-SYSTEM-RC                  PIC S9(4) COMP-5.
       01  SL-TMP-LEN                    PIC 9(4) COMP.
       01  SL-DELETE-CMD                 PIC X(300).

       LINKAGE SECTION.
       COPY "shared-log-api.cpy".

       PROCEDURE DIVISION USING WS-LOG-MSG WS-LOG-RC.
       MAIN-LOGIC.
           IF SL-NOT-INITIALIZED THEN
               PERFORM SL-INIT
           END-IF.

           PERFORM SL-EMIT.
           GOBACK.

       SL-INIT.
           MOVE 'Y' TO SL-INIT-FLAG.
           ACCEPT SL-ENV-VAL FROM ENVIRONMENT 'PB_LOG_LEVEL'.
           IF SL-ENV-VAL = SPACES THEN
               MOVE 'INFO ' TO SL-MIN-LEVEL
           ELSE
               MOVE SL-ENV-VAL(1:5) TO SL-MIN-LEVEL
           END-IF.

           PERFORM SL-COMPUTE-PATH.

           OPEN OUTPUT LOG-FILE.
           IF SL-FILE-STATUS = '00' OR SL-FILE-STATUS = '05' THEN
               MOVE 'Y' TO SL-FILE-OPEN
               MOVE 'N' TO SL-FALLBACK-MODE
           ELSE
               MOVE 'N' TO SL-FILE-OPEN
               MOVE 'Y' TO SL-FALLBACK-MODE
               DISPLAY "[SHARED-LOG] WARNING: primary log file "
                       "unavailable; falling back to stderr"
                       UPON SYSERR
               DISPLAY "  attempted path: " SL-FILE-PATH
                       UPON SYSERR
               DISPLAY "  file-status:    " SL-FILE-STATUS
                       UPON SYSERR
           END-IF.

       SL-COMPUTE-PATH.
           MOVE FUNCTION CURRENT-DATE TO SL-CD.
           CALL "C$GETPID" RETURNING SL-PID
               ON EXCEPTION
                   MOVE 1 TO SL-PID
           END-CALL.
           MOVE SL-PID TO SL-PID-DISP.

           STRING
               SL-CD-YYYY    DELIMITED BY SIZE
               SL-CD-MM      DELIMITED BY SIZE
               SL-CD-DD      DELIMITED BY SIZE
               "-"           DELIMITED BY SIZE
               SL-CD-HH      DELIMITED BY SIZE
               SL-CD-MI      DELIMITED BY SIZE
               SL-CD-SS      DELIMITED BY SIZE
               "-"           DELIMITED BY SIZE
               FUNCTION TRIM(SL-PID-DISP) DELIMITED BY SIZE
               INTO SL-DATE-SUFFIX
           END-STRING.

           STRING
               FUNCTION TRIM(SL-LOG-DIR) DELIMITED BY SIZE
               "/"                       DELIMITED BY SIZE
               FUNCTION TRIM(WS-LOG-SUBSYSTEM) DELIMITED BY SIZE
               "-"                       DELIMITED BY SIZE
               FUNCTION TRIM(SL-DATE-SUFFIX) DELIMITED BY SIZE
               ".log"                    DELIMITED BY SIZE
               INTO SL-FILE-PATH
           END-STRING.

       SL-EMIT.
           MOVE 0 TO WS-LOG-RC.
           PERFORM SL-CHECK-LEVEL.
           IF SL-SHOULD-SKIP THEN
               EXIT PARAGRAPH
           END-IF.

           PERFORM SL-FORMAT-MSG.

           IF SL-IN-FALLBACK THEN
               PERFORM SL-WRITE-STDERR
               MOVE 2 TO WS-LOG-RC
           ELSE
               PERFORM SL-WRITE-FILE
           END-IF.

           IF WS-LOG-LEVEL = 'ERROR' THEN
               PERFORM SL-JOURNALD-EMIT
           END-IF.

       SL-CHECK-LEVEL.
           MOVE 'Y' TO SL-EMIT-FLAG.
           EVALUATE SL-MIN-LEVEL
               WHEN 'DEBUG'
                   MOVE 'Y' TO SL-EMIT-FLAG
               WHEN 'INFO '
                   IF WS-LOG-LEVEL = 'DEBUG' THEN
                       MOVE 'N' TO SL-EMIT-FLAG
                   END-IF
               WHEN 'WARN '
                   IF WS-LOG-LEVEL = 'DEBUG' OR
                      WS-LOG-LEVEL = 'INFO ' THEN
                       MOVE 'N' TO SL-EMIT-FLAG
                   END-IF
               WHEN 'ERROR'
                   IF WS-LOG-LEVEL NOT = 'ERROR' THEN
                       MOVE 'N' TO SL-EMIT-FLAG
                   END-IF
               WHEN OTHER
                   MOVE 'Y' TO SL-EMIT-FLAG
           END-EVALUATE.

       SL-FORMAT-TIMESTAMP.
           MOVE FUNCTION CURRENT-DATE TO SL-CD.
           STRING
               SL-CD-YYYY  DELIMITED BY SIZE
               "-"         DELIMITED BY SIZE
               SL-CD-MM    DELIMITED BY SIZE
               "-"         DELIMITED BY SIZE
               SL-CD-DD    DELIMITED BY SIZE
               "T"         DELIMITED BY SIZE
               SL-CD-HH    DELIMITED BY SIZE
               ":"         DELIMITED BY SIZE
               SL-CD-MI    DELIMITED BY SIZE
               ":"         DELIMITED BY SIZE
               SL-CD-SS    DELIMITED BY SIZE
               "."         DELIMITED BY SIZE
               SL-CD-MS    DELIMITED BY SIZE
               "0"         DELIMITED BY SIZE
               SL-CD-TZSIGN DELIMITED BY SIZE
               SL-CD-TZHH  DELIMITED BY SIZE
               ":"         DELIMITED BY SIZE
               SL-CD-TZMM  DELIMITED BY SIZE
               INTO SL-TS
           END-STRING.

       SL-FORMAT-MSG.
           PERFORM SL-FORMAT-TIMESTAMP.
           MOVE SPACES TO SL-FORMATTED-MSG.
           STRING
               SL-TS               DELIMITED BY SIZE
               " ["                DELIMITED BY SIZE
               WS-LOG-LEVEL        DELIMITED BY SIZE
               "] ["               DELIMITED BY SIZE
               FUNCTION TRIM(WS-LOG-SUBSYSTEM) DELIMITED BY SIZE
               "] ["               DELIMITED BY SIZE
               FUNCTION TRIM(SL-PID-DISP) DELIMITED BY SIZE
               "] "                DELIMITED BY SIZE
               FUNCTION TRIM(WS-LOG-MESSAGE) DELIMITED BY SIZE
               INTO SL-FORMATTED-MSG
           END-STRING.

       SL-WRITE-FILE.
           MOVE SL-FORMATTED-MSG TO LOG-REC.
           WRITE LOG-REC.
           IF SL-FILE-STATUS NOT = '00' THEN
               MOVE 'Y' TO SL-FALLBACK-MODE
               DISPLAY "[SHARED-LOG] WARNING: write failed file-status="
                       SL-FILE-STATUS " falling back to stderr"
                       UPON SYSERR
               PERFORM SL-WRITE-STDERR
               MOVE 2 TO WS-LOG-RC
           END-IF.

       SL-WRITE-STDERR.
           DISPLAY FUNCTION TRIM(SL-FORMATTED-MSG) UPON SYSERR.

       SL-JOURNALD-EMIT.
           MOVE SPACES TO SL-LOGGER-CMD.
           STRING
               "logger -t "        DELIMITED BY SIZE
               FUNCTION TRIM(WS-LOG-SUBSYSTEM) DELIMITED BY SIZE
               " -p user.err "     DELIMITED BY SIZE
               "'"                 DELIMITED BY SIZE
               FUNCTION TRIM(WS-LOG-MESSAGE) DELIMITED BY SIZE
               "'"                 DELIMITED BY SIZE
               INTO SL-LOGGER-CMD
           END-STRING.
           CALL "SYSTEM" USING SL-LOGGER-CMD
               RETURNING SL-SYSTEM-RC
               ON EXCEPTION
                   CONTINUE
           END-CALL.

       SL-FINALIZE.
           IF SL-FILE-IS-OPEN THEN
               CLOSE LOG-FILE
               MOVE 'N' TO SL-FILE-OPEN
           END-IF.

       END PROGRAM SHARED-LOG.
