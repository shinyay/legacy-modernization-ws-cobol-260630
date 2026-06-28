       IDENTIFICATION DIVISION.
       PROGRAM-ID. TXVAL-REPORT-SUMMARY.

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
       01  SUM-LINE             PIC X(200).
       FD  REPORT-OUT-FILE.
       01  RPT-LINE             PIC X(200).

       WORKING-STORAGE SECTION.
       01  WS-IN-PATH           PIC X(80) VALUE SPACES.
       01  WS-OUT-PATH          PIC X(80) VALUE SPACES.
       01  WS-FS-IN             PIC X(2).
       01  WS-FS-OUT            PIC X(2).
       01  WS-EOF               PIC X(1) VALUE "N".
           88  WS-EOF-Y                  VALUE "Y".
       01  WS-LINES-WRITTEN     PIC 9(5) VALUE 0.
       01  WS-LINES-READ        PIC 9(5) VALUE 0.
       01  WS-TMP-LINE          PIC X(200).
       01  WS-BATCH-DISP        PIC X(14).

       LINKAGE SECTION.
           COPY "tx-val-api.cpy".

       PROCEDURE DIVISION USING TXVAL-REPORT-INPUT
                                TXVAL-REPORT-OUTPUT.
       MAIN-LOGIC.
           MOVE 0 TO TXVAL-RP-OUT-LINES-WRITTEN
           SET TXVAL-RP-OK TO TRUE
           MOVE FUNCTION TRIM(TXVAL-RP-IN-SUMMARY-FILENAME)
               TO WS-IN-PATH
           MOVE FUNCTION TRIM(TXVAL-RP-IN-REPORT-FILENAME)
               TO WS-OUT-PATH
           MOVE TXVAL-RP-IN-BATCH-ID TO WS-BATCH-DISP

           OPEN INPUT SUMMARY-IN-FILE
           IF WS-FS-IN = "35"
               SET TXVAL-RP-IO-FAIL TO TRUE
               GOBACK
           END-IF
           IF WS-FS-IN NOT = "00"
               SET TXVAL-RP-FATAL TO TRUE
               GOBACK
           END-IF
           OPEN OUTPUT REPORT-OUT-FILE
           IF WS-FS-OUT NOT = "00"
               CLOSE SUMMARY-IN-FILE
               SET TXVAL-RP-IO-FAIL TO TRUE
               GOBACK
           END-IF

           PERFORM WRITE-HEADER
           PERFORM PROCESS-LOOP UNTIL WS-EOF-Y
           PERFORM WRITE-FOOTER

           CLOSE SUMMARY-IN-FILE
           CLOSE REPORT-OUT-FILE
           MOVE WS-LINES-WRITTEN TO TXVAL-RP-OUT-LINES-WRITTEN
           IF WS-LINES-READ = 0 AND WS-LINES-WRITTEN < 5
               SET TXVAL-RP-EMPTY TO TRUE
           END-IF
           GOBACK.

       WRITE-HEADER.
           MOVE SPACES TO RPT-LINE
           STRING "# 10-txnvalidate batch summary"
               DELIMITED BY SIZE INTO RPT-LINE
           PERFORM WRITE-LINE
           MOVE SPACES TO RPT-LINE
           PERFORM WRITE-LINE
           MOVE SPACES TO RPT-LINE
           STRING "Batch ID: " WS-BATCH-DISP
               DELIMITED BY SIZE INTO RPT-LINE
           PERFORM WRITE-LINE
           MOVE SPACES TO RPT-LINE
           PERFORM WRITE-LINE
           MOVE SPACES TO RPT-LINE
           STRING "## Metrics" DELIMITED BY SIZE INTO RPT-LINE
           PERFORM WRITE-LINE
           MOVE SPACES TO RPT-LINE
           PERFORM WRITE-LINE.

       PROCESS-LOOP.
           READ SUMMARY-IN-FILE INTO WS-TMP-LINE
               AT END
                   SET WS-EOF-Y TO TRUE
                   EXIT PARAGRAPH
           END-READ
           ADD 1 TO WS-LINES-READ
           MOVE WS-TMP-LINE TO RPT-LINE
           PERFORM WRITE-LINE.

       WRITE-FOOTER.
           MOVE SPACES TO RPT-LINE
           PERFORM WRITE-LINE
           MOVE SPACES TO RPT-LINE
           STRING "## End of report"
               DELIMITED BY SIZE INTO RPT-LINE
           PERFORM WRITE-LINE.

       WRITE-LINE.
           WRITE RPT-LINE
           ADD 1 TO WS-LINES-WRITTEN.

       END PROGRAM TXVAL-REPORT-SUMMARY.
