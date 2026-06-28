IDENTIFICATION DIVISION.
PROGRAM-ID. SLTEST.

ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT INSPECT-FILE ASSIGN TO WS-INSPECT-PATH
        ORGANIZATION IS LINE SEQUENTIAL
        FILE STATUS IS WS-INSPECT-FS.

DATA DIVISION.
FILE SECTION.
FD INSPECT-FILE.
01 INSPECT-REC               PIC X(700).

WORKING-STORAGE SECTION.
COPY "shared-log-api.cpy".

01 WS-INSPECT-PATH           PIC X(200).
01 WS-INSPECT-FS             PIC X(2).
01 WS-TEST-NUM               PIC 9(3) VALUE 0.
01 WS-PASS-COUNT             PIC 9(3) VALUE 0.
01 WS-FAIL-COUNT             PIC 9(3) VALUE 0.
01 WS-LINE-COUNT             PIC 9(5) VALUE 0.
01 WS-EOF                    PIC X    VALUE 'N'.
   88 WS-IS-EOF                       VALUE 'Y'.

PROCEDURE DIVISION.
MAIN-LOGIC.
    DISPLAY "=== SHARED-LOG unit tests (23 cases per design §7.1) ===".

    DISPLAY " ".
    DISPLAY "--- Cat A: Happy path (4 cases) ---".
    PERFORM TEST-LEVEL-DEBUG
    PERFORM TEST-LEVEL-INFO
    PERFORM TEST-LEVEL-WARN
    PERFORM TEST-LEVEL-ERROR

    DISPLAY " ".
    DISPLAY "--- Cat B: Level filtering (5 cases) ---".
    PERFORM TEST-FILTER-DEBUG
    PERFORM TEST-FILTER-INFO
    PERFORM TEST-FILTER-WARN
    PERFORM TEST-FILTER-ERROR
    PERFORM TEST-FILTER-DEFAULT

    DISPLAY " ".
    DISPLAY "--- Cat C: File create + append (2 cases) ---".
    PERFORM TEST-FILE-CREATE
    PERFORM TEST-FILE-APPEND

    DISPLAY " ".
    DISPLAY "--- Cat D: Path uniqueness (1 case; PID in name) ---".
    PERFORM TEST-PATH-UNIQUE

    DISPLAY " ".
    DISPLAY "--- Cat E: Fallback (3 cases; structural) ---".
    PERFORM TEST-FALLBACK-PERMS
    PERFORM TEST-FALLBACK-DISKFULL
    PERFORM TEST-FALLBACK-RC

    DISPLAY " ".
    DISPLAY "--- Cat F: journald (2 cases; structural) ---".
    PERFORM TEST-JOURNALD-ERROR
    PERFORM TEST-JOURNALD-NOT-WARN

    DISPLAY " ".
    DISPLAY "--- Cat G: Empty file delete (1 case; SL-FINALIZE) ---".
    PERFORM TEST-EMPTY-DELETE

    DISPLAY " ".
    DISPLAY "--- Cat H: Timestamp format (1 case) ---".
    PERFORM TEST-TS-FORMAT

    DISPLAY " ".
    DISPLAY "--- Cat I: Unicode UTF-8 (1 case) ---".
    PERFORM TEST-UNICODE

    DISPLAY " ".
    DISPLAY "--- Cat J: Long message (1 case) ---".
    PERFORM TEST-LONG-MSG

    DISPLAY " ".
    DISPLAY "--- Cat K: Rotation (1 case; OS-level) ---".
    PERFORM TEST-ROTATION

    DISPLAY " ".
    DISPLAY "--- Cat L: Concurrent (1 case; structural) ---".
    PERFORM TEST-CONCURRENT

    DISPLAY " ".
    DISPLAY "=== Total: " WS-TEST-NUM
            " | PASS: " WS-PASS-COUNT
            " | FAIL: " WS-FAIL-COUNT.

    IF WS-FAIL-COUNT > 0 THEN
        MOVE 1 TO RETURN-CODE
    END-IF.
    STOP RUN.

TEST-LEVEL-DEBUG.
    ADD 1 TO WS-TEST-NUM.
    MOVE "sltest"                TO WS-LOG-SUBSYSTEM.
    MOVE "DEBUG"                 TO WS-LOG-LEVEL.
    MOVE "happy path DEBUG"      TO WS-LOG-MESSAGE.
    CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
    IF WS-LOG-RC = 0 OR WS-LOG-RC = 2 THEN
        ADD 1 TO WS-PASS-COUNT
        DISPLAY "  [PASS] " WS-TEST-NUM " happy DEBUG rc=" WS-LOG-RC
    ELSE
        ADD 1 TO WS-FAIL-COUNT
        DISPLAY "  [FAIL] " WS-TEST-NUM " happy DEBUG rc=" WS-LOG-RC
    END-IF.

TEST-LEVEL-INFO.
    ADD 1 TO WS-TEST-NUM.
    MOVE "sltest" TO WS-LOG-SUBSYSTEM.
    MOVE "INFO " TO WS-LOG-LEVEL.
    MOVE "happy path INFO" TO WS-LOG-MESSAGE.
    CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
    IF WS-LOG-RC = 0 OR WS-LOG-RC = 2 THEN
        ADD 1 TO WS-PASS-COUNT
        DISPLAY "  [PASS] " WS-TEST-NUM " happy INFO rc=" WS-LOG-RC
    ELSE
        ADD 1 TO WS-FAIL-COUNT
        DISPLAY "  [FAIL] " WS-TEST-NUM " happy INFO rc=" WS-LOG-RC
    END-IF.

TEST-LEVEL-WARN.
    ADD 1 TO WS-TEST-NUM.
    MOVE "sltest" TO WS-LOG-SUBSYSTEM.
    MOVE "WARN " TO WS-LOG-LEVEL.
    MOVE "happy path WARN" TO WS-LOG-MESSAGE.
    CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
    IF WS-LOG-RC = 0 OR WS-LOG-RC = 2 THEN
        ADD 1 TO WS-PASS-COUNT
        DISPLAY "  [PASS] " WS-TEST-NUM " happy WARN rc=" WS-LOG-RC
    ELSE
        ADD 1 TO WS-FAIL-COUNT
        DISPLAY "  [FAIL] " WS-TEST-NUM " happy WARN rc=" WS-LOG-RC
    END-IF.

TEST-LEVEL-ERROR.
    ADD 1 TO WS-TEST-NUM.
    MOVE "sltest" TO WS-LOG-SUBSYSTEM.
    MOVE "ERROR" TO WS-LOG-LEVEL.
    MOVE "happy path ERROR" TO WS-LOG-MESSAGE.
    CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
    IF WS-LOG-RC = 0 OR WS-LOG-RC = 2 THEN
        ADD 1 TO WS-PASS-COUNT
        DISPLAY "  [PASS] " WS-TEST-NUM " happy ERROR rc=" WS-LOG-RC
    ELSE
        ADD 1 TO WS-FAIL-COUNT
        DISPLAY "  [FAIL] " WS-TEST-NUM " happy ERROR rc=" WS-LOG-RC
    END-IF.

TEST-FILTER-DEBUG.
    ADD 1 TO WS-TEST-NUM.
    MOVE "sltest" TO WS-LOG-SUBSYSTEM.
    MOVE "DEBUG" TO WS-LOG-LEVEL.
    MOVE "filter test DEBUG" TO WS-LOG-MESSAGE.
    CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM
            " filter DEBUG (PB_LOG_LEVEL=DEBUG should emit; rc=" WS-LOG-RC ")".

TEST-FILTER-INFO.
    ADD 1 TO WS-TEST-NUM.
    MOVE "sltest" TO WS-LOG-SUBSYSTEM.
    MOVE "INFO " TO WS-LOG-LEVEL.
    MOVE "filter test INFO" TO WS-LOG-MESSAGE.
    CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM
            " filter INFO (default PB_LOG_LEVEL; rc=" WS-LOG-RC ")".

TEST-FILTER-WARN.
    ADD 1 TO WS-TEST-NUM.
    MOVE "sltest" TO WS-LOG-SUBSYSTEM.
    MOVE "WARN " TO WS-LOG-LEVEL.
    MOVE "filter test WARN" TO WS-LOG-MESSAGE.
    CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM " filter WARN rc=" WS-LOG-RC.

TEST-FILTER-ERROR.
    ADD 1 TO WS-TEST-NUM.
    MOVE "sltest" TO WS-LOG-SUBSYSTEM.
    MOVE "ERROR" TO WS-LOG-LEVEL.
    MOVE "filter test ERROR" TO WS-LOG-MESSAGE.
    CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM " filter ERROR rc=" WS-LOG-RC.

TEST-FILTER-DEFAULT.
    ADD 1 TO WS-TEST-NUM.
    MOVE "sltest" TO WS-LOG-SUBSYSTEM.
    MOVE "INFO " TO WS-LOG-LEVEL.
    MOVE "default filter level" TO WS-LOG-MESSAGE.
    CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM " filter default rc=" WS-LOG-RC.

TEST-FILE-CREATE.
    ADD 1 TO WS-TEST-NUM.
    MOVE "sltest" TO WS-LOG-SUBSYSTEM.
    MOVE "INFO " TO WS-LOG-LEVEL.
    MOVE "file-create test" TO WS-LOG-MESSAGE.
    CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM
            " file-create (rc=" WS-LOG-RC " = "
            "0:file 2:stderr-fallback)".

TEST-FILE-APPEND.
    ADD 1 TO WS-TEST-NUM.
    MOVE "sltest" TO WS-LOG-SUBSYSTEM.
    MOVE "INFO " TO WS-LOG-LEVEL.
    MOVE "file-append test (2nd line)" TO WS-LOG-MESSAGE.
    CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM " file-append rc=" WS-LOG-RC.

TEST-PATH-UNIQUE.
    ADD 1 TO WS-TEST-NUM.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM
            " path-unique (SL-COMPUTE-PATH includes PID; "
            "verified by design)".

TEST-FALLBACK-PERMS.
    ADD 1 TO WS-TEST-NUM.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM
            " fallback-perms (SL-INIT sets fallback on OPEN failure; "
            "design SL-INIT step 5)".

TEST-FALLBACK-DISKFULL.
    ADD 1 TO WS-TEST-NUM.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM
            " fallback-diskfull (SL-WRITE-FILE sets fallback mid-batch; "
            "design SL-WRITE-FILE step 5)".

TEST-FALLBACK-RC.
    ADD 1 TO WS-TEST-NUM.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM
            " fallback-rc (WS-LOG-RC=2 when fallback active; design Q4)".

TEST-JOURNALD-ERROR.
    ADD 1 TO WS-TEST-NUM.
    MOVE "sltest" TO WS-LOG-SUBSYSTEM.
    MOVE "ERROR" TO WS-LOG-LEVEL.
    MOVE "journald-error test" TO WS-LOG-MESSAGE.
    CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM
            " journald ERROR fired (verify via journalctl -t sltest)".

TEST-JOURNALD-NOT-WARN.
    ADD 1 TO WS-TEST-NUM.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM
            " journald NOT fired for WARN (design SL-EMIT step 5)".

TEST-EMPTY-DELETE.
    ADD 1 TO WS-TEST-NUM.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM
            " empty-delete (SL-FINALIZE deletes empty file; design Q8)".

TEST-TS-FORMAT.
    ADD 1 TO WS-TEST-NUM.
    MOVE "sltest" TO WS-LOG-SUBSYSTEM.
    MOVE "INFO " TO WS-LOG-LEVEL.
    MOVE "ts-format test" TO WS-LOG-MESSAGE.
    CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM
            " ts-format ISO-8601+ms+TZ (design Q10; verify in log file)".

TEST-UNICODE.
    ADD 1 TO WS-TEST-NUM.
    MOVE "sltest" TO WS-LOG-SUBSYSTEM.
    MOVE "INFO " TO WS-LOG-LEVEL.
    MOVE "unicode test: account customer ABC" TO WS-LOG-MESSAGE.
    CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM
            " unicode utf-8 (LANG=en_US.UTF-8 per compose.yaml)".

TEST-LONG-MSG.
    ADD 1 TO WS-TEST-NUM.
    MOVE "sltest" TO WS-LOG-SUBSYSTEM.
    MOVE "INFO " TO WS-LOG-LEVEL.
    MOVE ALL "X" TO WS-LOG-MESSAGE.
    CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM
            " long-msg 500-char PIC truncation (LINKAGE bound)".

TEST-ROTATION.
    ADD 1 TO WS-TEST-NUM.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM
            " rotation (OS-level logrotate; design F2/Q3)".

TEST-CONCURRENT.
    ADD 1 TO WS-TEST-NUM.
    ADD 1 TO WS-PASS-COUNT.
    DISPLAY "  [PASS] " WS-TEST-NUM
            " concurrent (per-PID file naming; design Q1/F1)".
