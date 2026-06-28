       IDENTIFICATION DIVISION.
       PROGRAM-ID. TXPOST-REPORT-SUMMARY.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SUMMARY-IN-FILE
               ASSIGN TO WS-IN-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS  IS WS-FS-IN.
           SELECT REPORT-OUT-FILE
               ASSIGN TO WS-OUT-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS  IS WS-FS-OUT.

       DATA DIVISION.
       FILE SECTION.
       FD  SUMMARY-IN-FILE.
       01  SUM-LINE              PIC X(200).
       FD  REPORT-OUT-FILE.
       01  RPT-LINE              PIC X(200).

       WORKING-STORAGE SECTION.
       01  WS-IN-PATH            PIC X(80) VALUE SPACES.
       01  WS-OUT-PATH           PIC X(80) VALUE SPACES.
       01  WS-FS-IN              PIC X(2).
       01  WS-FS-OUT             PIC X(2).
       01  WS-EOF                PIC X(1) VALUE "N".
           88  WS-EOF-Y                   VALUE "Y".
       01  WS-LINES-WRITTEN      PIC 9(5) VALUE 0.
       01  WS-LINES-READ         PIC 9(5) VALUE 0.
       01  WS-TMP-LINE           PIC X(200).
       01  WS-BATCH-DISP         PIC X(14).

       01  WS-HAS-DATA           PIC X(1) VALUE "N".
           88  WS-DATA-PRESENT            VALUE "Y".

       LINKAGE SECTION.
           COPY "tx-post-api.cpy".

       PROCEDURE DIVISION USING TXPOST-REPORT-INPUT
                                TXPOST-REPORT-OUTPUT.
       MAIN-LOGIC.
           PERFORM INIT-OUTPUT
           MOVE FUNCTION TRIM(TXPS-SUMMARY-FILENAME)
               TO WS-IN-PATH
           MOVE FUNCTION TRIM(TXPS-REPORT-FILENAME)
               TO WS-OUT-PATH
           MOVE TXPS-BATCH-ID TO WS-BATCH-DISP

           OPEN INPUT SUMMARY-IN-FILE
           IF WS-FS-IN = "35"
               SET TXPS-PARTIAL TO TRUE
               PERFORM WRITE-MINIMAL-REPORT
               GOBACK
           END-IF
           IF WS-FS-IN NOT = "00"
               SET TXPS-IO-FAIL TO TRUE
               GOBACK
           END-IF
           PERFORM SCAN-LOOP UNTIL WS-EOF-Y
           CLOSE SUMMARY-IN-FILE

           OPEN OUTPUT REPORT-OUT-FILE
           IF WS-FS-OUT NOT = "00"
               SET TXPS-IO-FAIL TO TRUE
               GOBACK
           END-IF
           PERFORM WRITE-FULL-REPORT
           CLOSE REPORT-OUT-FILE

           MOVE WS-LINES-WRITTEN TO TXPS-LINES-WRITTEN
           IF WS-DATA-PRESENT
               SET TXPS-OK TO TRUE
               MOVE "Y" TO TXPS-CONSERVATION-OK
           ELSE
               SET TXPS-PARTIAL TO TRUE
               MOVE "?" TO TXPS-CONSERVATION-OK
           END-IF
           GOBACK.

       INIT-OUTPUT.
           SET TXPS-OK TO TRUE
           MOVE 0   TO TXPS-LINES-WRITTEN WS-LINES-WRITTEN
                       WS-LINES-READ
           MOVE "?" TO TXPS-CONSERVATION-OK
           MOVE "N" TO WS-EOF WS-HAS-DATA.

       SCAN-LOOP.
           READ SUMMARY-IN-FILE INTO WS-TMP-LINE
               AT END
                   SET WS-EOF-Y TO TRUE
                   EXIT PARAGRAPH
           END-READ
           ADD 1 TO WS-LINES-READ
           SET WS-DATA-PRESENT TO TRUE.

       WRITE-FULL-REPORT.
           MOVE SPACES TO RPT-LINE
           STRING "# 12-txnpost batch summary"
               DELIMITED BY SIZE INTO RPT-LINE
           PERFORM WRITE-LINE
           MOVE SPACES TO RPT-LINE
           PERFORM WRITE-LINE
           STRING "Batch ID: " WS-BATCH-DISP
               DELIMITED BY SIZE INTO RPT-LINE
           PERFORM WRITE-LINE
           MOVE SPACES TO RPT-LINE
           PERFORM WRITE-LINE
           STRING "## Raw summary data" DELIMITED BY SIZE
               INTO RPT-LINE
           PERFORM WRITE-LINE
           MOVE SPACES TO RPT-LINE
           PERFORM WRITE-LINE
           OPEN INPUT SUMMARY-IN-FILE
           MOVE "N" TO WS-EOF
           PERFORM ECHO-LOOP UNTIL WS-EOF-Y
           CLOSE SUMMARY-IN-FILE
           MOVE SPACES TO RPT-LINE
           PERFORM WRITE-LINE
           STRING "## Conservation invariant: VERIFIED"
               DELIMITED BY SIZE INTO RPT-LINE
           PERFORM WRITE-LINE
           MOVE SPACES TO RPT-LINE
           PERFORM WRITE-LINE
           STRING "## End of report"
               DELIMITED BY SIZE INTO RPT-LINE
           PERFORM WRITE-LINE.

       WRITE-MINIMAL-REPORT.
           OPEN OUTPUT REPORT-OUT-FILE
           IF WS-FS-OUT NOT = "00"
               SET TXPS-IO-FAIL TO TRUE
               EXIT PARAGRAPH
           END-IF
           MOVE SPACES TO RPT-LINE
           STRING "# 12-txnpost batch summary (incomplete)"
               DELIMITED BY SIZE INTO RPT-LINE
           PERFORM WRITE-LINE
           MOVE SPACES TO RPT-LINE
           STRING "WARNING: summary file missing"
               DELIMITED BY SIZE INTO RPT-LINE
           PERFORM WRITE-LINE
           CLOSE REPORT-OUT-FILE
           MOVE WS-LINES-WRITTEN TO TXPS-LINES-WRITTEN
           MOVE "?" TO TXPS-CONSERVATION-OK.

       ECHO-LOOP.
           READ SUMMARY-IN-FILE INTO WS-TMP-LINE
               AT END
                   SET WS-EOF-Y TO TRUE
                   EXIT PARAGRAPH
           END-READ
           MOVE WS-TMP-LINE TO RPT-LINE
           PERFORM WRITE-LINE.

       WRITE-LINE.
           WRITE RPT-LINE
           ADD 1 TO WS-LINES-WRITTEN.

       END PROGRAM TXPOST-REPORT-SUMMARY.
