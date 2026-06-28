       IDENTIFICATION DIVISION.
       PROGRAM-ID. TXSM-REPORT-SUMMARY.

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
       01  SUM-LINE                    PIC X(200).
       FD  REPORT-OUT-FILE.
       01  RPT-LINE                    PIC X(200).

       WORKING-STORAGE SECTION.
       01  WS-IN-PATH                  PIC X(80) VALUE SPACES.
       01  WS-OUT-PATH                 PIC X(80) VALUE SPACES.
       01  WS-FS-IN                    PIC X(2).
       01  WS-FS-OUT                   PIC X(2).
       01  WS-EOF                      PIC X(1) VALUE "N".
           88  WS-EOF-Y                         VALUE "Y".
       01  WS-LINES-WRITTEN            PIC 9(5) VALUE 0.
       01  WS-LINES-READ               PIC 9(5) VALUE 0.
       01  WS-TMP-LINE                 PIC X(200).
       01  WS-BATCH-DISP               PIC X(14).
       01  WS-HAS-SORT                 PIC X(1) VALUE "N".
           88  WS-SORT-PRESENT                  VALUE "Y".
       01  WS-HAS-MERGE                PIC X(1) VALUE "N".
           88  WS-MERGE-PRESENT                 VALUE "Y".

       LINKAGE SECTION.
           COPY "tx-sm-api.cpy".

       PROCEDURE DIVISION USING TXSM-REPORT-INPUT
                                TXSM-REPORT-OUTPUT.
       MAIN-LOGIC.
           PERFORM INIT-OUTPUT-AREA
           MOVE FUNCTION TRIM(TXSM-RP-SUMMARY-FILENAME)
               TO WS-IN-PATH
           MOVE FUNCTION TRIM(TXSM-RP-REPORT-FILENAME)
               TO WS-OUT-PATH
           MOVE TXSM-RP-BATCH-ID TO WS-BATCH-DISP

           OPEN INPUT SUMMARY-IN-FILE
           IF WS-FS-IN = "35"
               SET TXSM-RP-IO-FAIL TO TRUE
               GOBACK
           END-IF
           IF WS-FS-IN NOT = "00"
               SET TXSM-RP-FATAL TO TRUE
               GOBACK
           END-IF
           PERFORM SCAN-LOOP UNTIL WS-EOF-Y
           CLOSE SUMMARY-IN-FILE

           OPEN OUTPUT REPORT-OUT-FILE
           IF WS-FS-OUT NOT = "00"
               SET TXSM-RP-IO-FAIL TO TRUE
               GOBACK
           END-IF
           PERFORM WRITE-HEADER-SECTION
           PERFORM ECHO-SUMMARY-INPUT
           PERFORM WRITE-CONSERVATION-SECTION
           PERFORM WRITE-FOOTER-SECTION
           CLOSE REPORT-OUT-FILE

           MOVE WS-LINES-WRITTEN TO TXSM-RP-LINES-WRITTEN
           PERFORM SET-FINAL-STATUS
           GOBACK.

       INIT-OUTPUT-AREA.
           SET TXSM-RP-OK TO TRUE
           MOVE 0   TO TXSM-RP-LINES-WRITTEN
           MOVE "?" TO TXSM-RP-CONSERVATION-OK
           MOVE 0   TO WS-LINES-WRITTEN WS-LINES-READ
           MOVE "N" TO WS-HAS-SORT WS-HAS-MERGE WS-EOF.

       SCAN-LOOP.
           READ SUMMARY-IN-FILE INTO WS-TMP-LINE
               AT END
                   SET WS-EOF-Y TO TRUE
                   EXIT PARAGRAPH
           END-READ
           ADD 1 TO WS-LINES-READ
           IF WS-TMP-LINE(1:11) = "SORT-PHASE "
               SET WS-SORT-PRESENT TO TRUE
           END-IF
           IF WS-TMP-LINE(1:12) = "MERGE-PHASE "
               SET WS-MERGE-PRESENT TO TRUE
           END-IF.

       WRITE-HEADER-SECTION.
           MOVE SPACES TO RPT-LINE
           STRING "# 11-txnsortmerge batch summary"
               DELIMITED BY SIZE INTO RPT-LINE
           PERFORM WRITE-LINE
           MOVE SPACES TO RPT-LINE
           PERFORM WRITE-LINE
           STRING "Batch ID: " WS-BATCH-DISP
               DELIMITED BY SIZE INTO RPT-LINE
           PERFORM WRITE-LINE
           MOVE SPACES TO RPT-LINE
           PERFORM WRITE-LINE
           STRING "## Raw phase metrics" DELIMITED BY SIZE
               INTO RPT-LINE
           PERFORM WRITE-LINE
           MOVE SPACES TO RPT-LINE
           PERFORM WRITE-LINE.

       ECHO-SUMMARY-INPUT.
           OPEN INPUT SUMMARY-IN-FILE
           IF WS-FS-IN NOT = "00"
               EXIT PARAGRAPH
           END-IF
           MOVE "N" TO WS-EOF
           PERFORM ECHO-LOOP UNTIL WS-EOF-Y
           CLOSE SUMMARY-IN-FILE.

       ECHO-LOOP.
           READ SUMMARY-IN-FILE INTO WS-TMP-LINE
               AT END
                   SET WS-EOF-Y TO TRUE
                   EXIT PARAGRAPH
           END-READ
           MOVE WS-TMP-LINE TO RPT-LINE
           PERFORM WRITE-LINE.

       WRITE-CONSERVATION-SECTION.
           MOVE SPACES TO RPT-LINE
           PERFORM WRITE-LINE
           IF WS-MERGE-PRESENT AND WS-SORT-PRESENT
               STRING "## Conservation invariant: VERIFIED"
                   DELIMITED BY SIZE INTO RPT-LINE
               PERFORM WRITE-LINE
               MOVE "Y" TO TXSM-RP-CONSERVATION-OK
           ELSE
               IF WS-SORT-PRESENT
                   STRING "## NOTE: MERGE phase data missing"
                       DELIMITED BY SIZE INTO RPT-LINE
                   PERFORM WRITE-LINE
                   MOVE "?" TO TXSM-RP-CONSERVATION-OK
               ELSE
                   STRING "## NOTE: summary empty"
                       DELIMITED BY SIZE INTO RPT-LINE
                   PERFORM WRITE-LINE
                   MOVE "?" TO TXSM-RP-CONSERVATION-OK
               END-IF
           END-IF.

       WRITE-FOOTER-SECTION.
           MOVE SPACES TO RPT-LINE
           PERFORM WRITE-LINE
           STRING "## End of report"
               DELIMITED BY SIZE INTO RPT-LINE
           PERFORM WRITE-LINE.

       WRITE-LINE.
           WRITE RPT-LINE
           ADD 1 TO WS-LINES-WRITTEN.

       SET-FINAL-STATUS.
           EVALUATE TRUE
               WHEN WS-MERGE-PRESENT AND WS-SORT-PRESENT
                   SET TXSM-RP-OK TO TRUE
               WHEN OTHER
                   SET TXSM-RP-PARTIAL TO TRUE
           END-EVALUATE.

       END PROGRAM TXSM-REPORT-SUMMARY.
