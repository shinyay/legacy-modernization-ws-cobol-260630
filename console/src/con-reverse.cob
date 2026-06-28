       IDENTIFICATION DIVISION.
       PROGRAM-ID. CON-REVERSE.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT REQ-FILE ASSIGN TO WS-REQ-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REQ-FS.
           SELECT RES-FILE ASSIGN TO WS-RES-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-RES-FS.

       DATA DIVISION.
       FILE SECTION.
       FD  REQ-FILE.
       01  REQ-REC                   PIC X(120).
       FD  RES-FILE.
       01  RES-REC                   PIC X(160).

       WORKING-STORAGE SECTION.
       01  WS-DIR                    PIC X(180) VALUE SPACES.
       01  WS-REQ-PATH               PIC X(200) VALUE SPACES.
       01  WS-RES-PATH               PIC X(200) VALUE SPACES.
       01  WS-REQ-FS                 PIC X(2)   VALUE "00".
       01  WS-RES-FS                 PIC X(2)   VALUE "00".
       01  WS-EOF                    PIC X(1)   VALUE "N".
       01  WS-LINE-NO                PIC 9(2)   VALUE 0.

       01  WS-REQ-ID                 PIC X(20)  VALUE SPACES.
       01  WS-TXN                    PIC X(18)  VALUE SPACES.
       01  WS-REASON                 PIC X(80)  VALUE SPACES.
       01  WS-OPER                   PIC X(20)  VALUE SPACES.

       01  WS-INPUT-OK               PIC X(1)   VALUE "Y".
       01  WS-EXITCODE               PIC 9(3)   VALUE 0.
       01  WS-IDX                    PIC 9(2)   VALUE 0.
       01  WS-RESULT-LINE            PIC X(160) VALUE SPACES.

       COPY "tx-post-api.cpy".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           PERFORM BUILD-PATHS
           PERFORM READ-REQUEST
           IF WS-REQ-FS NOT = "00"
               MOVE 2 TO RETURN-CODE
               STOP RUN
           END-IF
           PERFORM VALIDATE-INPUT
           IF WS-INPUT-OK = "Y"
               PERFORM DO-REVERSE
           ELSE
               SET TXPV-INVALID TO TRUE
               MOVE SPACES TO TXPV-NEW-RV-TXN-ID
               MOVE "N" TO TXPV-IN-DOUBT-RESOLVED
           END-IF
           PERFORM MAP-EXIT-CODE
           PERFORM WRITE-RESULT
           MOVE WS-EXITCODE TO RETURN-CODE
           STOP RUN.

       BUILD-PATHS.
           MOVE SPACES TO WS-DIR
           ACCEPT WS-DIR FROM ENVIRONMENT "CONSOLE_REVS_DIR"
           IF WS-DIR = SPACES
               MOVE "/tmp/console-demo/revs" TO WS-DIR
           END-IF
           STRING FUNCTION TRIM(WS-DIR) "/request.txt"
                  DELIMITED BY SIZE INTO WS-REQ-PATH
           STRING FUNCTION TRIM(WS-DIR) "/result.txt"
                  DELIMITED BY SIZE INTO WS-RES-PATH.

       READ-REQUEST.
           MOVE "N" TO WS-EOF
           MOVE 0 TO WS-LINE-NO
           OPEN INPUT REQ-FILE
           IF WS-REQ-FS NOT = "00"
               EXIT PARAGRAPH
           END-IF
           PERFORM UNTIL WS-EOF = "Y"
               READ REQ-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END PERFORM STORE-REQ-LINE
               END-READ
           END-PERFORM
           CLOSE REQ-FILE.

       STORE-REQ-LINE.
           ADD 1 TO WS-LINE-NO
           EVALUATE WS-LINE-NO
               WHEN 1 MOVE REQ-REC(1:20) TO WS-REQ-ID
               WHEN 2 MOVE REQ-REC(1:18) TO WS-TXN
               WHEN 3 MOVE REQ-REC(1:80) TO WS-REASON
               WHEN 4 MOVE REQ-REC(1:20) TO WS-OPER
               WHEN OTHER CONTINUE
           END-EVALUATE.

       VALIDATE-INPUT.
           MOVE "Y" TO WS-INPUT-OK
           IF WS-LINE-NO < 4
               MOVE "N" TO WS-INPUT-OK
           END-IF
           IF WS-TXN IS NOT NUMERIC
               MOVE "N" TO WS-INPUT-OK
           END-IF
           IF WS-REASON = SPACES OR WS-OPER = SPACES
               MOVE "N" TO WS-INPUT-OK
           END-IF.

       DO-REVERSE.
           MOVE WS-TXN    TO TXPV-ORIG-TXN-ID
           MOVE WS-REASON TO TXPV-REVERSAL-REASON
           MOVE WS-OPER   TO TXPV-OPERATOR-ID
           CALL "TXPOST-REVERSE"
                USING TXPOST-REVERSE-INPUT TXPOST-REVERSE-OUTPUT.

       MAP-EXIT-CODE.
           EVALUATE TXPV-STATUS
               WHEN "00" MOVE 0  TO WS-EXITCODE
               WHEN "04" MOVE 4  TO WS-EXITCODE
               WHEN "08" MOVE 8  TO WS-EXITCODE
               WHEN "12" MOVE 12 TO WS-EXITCODE
               WHEN "16" MOVE 16 TO WS-EXITCODE
               WHEN OTHER MOVE 16 TO WS-EXITCODE
           END-EVALUATE.

       WRITE-RESULT.
           MOVE SPACES TO WS-RESULT-LINE
           STRING FUNCTION TRIM(WS-REQ-ID) "|"
                  TXPV-STATUS "|"
                  TXPV-NEW-RV-TXN-ID "|"
                  TXPV-IN-DOUBT-RESOLVED
                  DELIMITED BY SIZE INTO WS-RESULT-LINE
           OPEN OUTPUT RES-FILE
           IF WS-RES-FS NOT = "00"
               EXIT PARAGRAPH
           END-IF
           MOVE WS-RESULT-LINE TO RES-REC
           WRITE RES-REC
           CLOSE RES-FILE.
