       IDENTIFICATION DIVISION.
       PROGRAM-ID. INTI-DECODE-BATCH.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EBCDIC-FILE
               ASSIGN TO WS-INPUT-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-IN.
           SELECT DECODED-FILE
               ASSIGN TO WS-OUTPUT-PATH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-OUT.
           SELECT REJECT-FILE
               ASSIGN TO WS-REJECT-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FS-REJ.

       DATA DIVISION.
       FILE SECTION.
       FD  EBCDIC-FILE
           RECORD CONTAINS 800 CHARACTERS.
       01  EBCDIC-IN-REC             PIC X(800).

       FD  DECODED-FILE
           RECORD CONTAINS 600 CHARACTERS.
       01  DECODED-OUT-REC           PIC X(600).

       FD  REJECT-FILE.
       01  REJECT-LINE               PIC X(200).

       WORKING-STORAGE SECTION.

       01  WS-FS-IN                  PIC X(2).
       01  WS-FS-OUT                 PIC X(2).
       01  WS-FS-REJ                 PIC X(2).

       01  WS-INPUT-PATH             PIC X(120).
       01  WS-OUTPUT-PATH            PIC X(120).
       01  WS-REJECT-PATH            PIC X(120).

       01  WS-EOF-FLAG               PIC X(1) VALUE "N".
           88  WS-EOF                         VALUE "Y".
       01  WS-OUT-OPEN               PIC X(1) VALUE "N".
       01  WS-REJ-OPEN               PIC X(1) VALUE "N".
       01  WS-IN-OPEN                PIC X(1) VALUE "N".
       01  WS-HEADER-SEEN            PIC X(1) VALUE "N".
       01  WS-TRAILER-SEEN           PIC X(1) VALUE "N".
       01  WS-CHECKSUM-MATCH-FLAG    PIC X(1) VALUE "Y".
       01  WS-THRESHOLD-BREACH       PIC X(1) VALUE "N".

       01  WS-CTR-READ               PIC 9(10) VALUE 0.
       01  WS-CTR-DECODED            PIC 9(10) VALUE 0.
       01  WS-CTR-REJECTED           PIC 9(10) VALUE 0.
       01  WS-REJECT-PCT             PIC 9(3)  VALUE 0.

       01  WS-CHECKSUM-ACC           PIC 9(10) VALUE 0.
       01  WS-CHECKSUM-OUT           PIC 9(5)  VALUE 0.
       01  WS-IDX                    PIC 9(4).
       01  WS-BYTE-VAL               PIC 9(3).
       01  WS-BYTE-CHAR              PIC X(1).

       01  WS-DATE-Y                 PIC 9(4).
       01  WS-DATE-M                 PIC 9(2).
       01  WS-DATE-D                 PIC 9(2).
       01  WS-DATE-YY                PIC 9(2).

       01  WS-SENTINEL-EXISTS        PIC X(1).
       01  WS-CMD                    PIC X(200).
       01  WS-CMD-RC                 PIC S9(4) COMP.

       01  WS-DECODED-BUF            PIC X(2400).
       01  WS-DECODED-LEN            PIC S9(9) COMP-5.

       01  WS-CURRENT-TYPE           PIC X(1).
       01  WS-CURRENT-CAT-IN         PIC 9(2).
       01  WS-CURRENT-CAT-OUT        PIC X(2).
       01  WS-CURRENT-AMOUNT         PIC 9(15).
       01  WS-CURRENT-DATE-YY        PIC 9(2).
       01  WS-CURRENT-DATE-MM        PIC 9(2).
       01  WS-CURRENT-DATE-DD        PIC 9(2).
       01  WS-CURRENT-DATE-YYYY      PIC 9(8).
       01  WS-CURRENT-PAYER-ACCT     PIC X(13).
       01  WS-CURRENT-PAYEE-ACCT     PIC X(13).
       01  WS-CURRENT-DESC           PIC X(120).
       01  WS-CURRENT-SEQ            PIC 9(10).
       01  WS-CURRENT-BRANCH         PIC 9(3).
       01  WS-CURRENT-PRODUCT        PIC 9(3).
       01  WS-CURRENT-BANK           PIC 9(4).
       01  WS-CURRENT-REASON         PIC X(4).

       01  WS-T-RECORD-COUNT         PIC 9(10).
       01  WS-T-CHECKSUM             PIC X(40).

           COPY "ws-txn-decoded-record.cpy".

       01  EBCDIC-DECODED.
           05  ED-WORK-REC             PIC X(800).
       01  EBCDIC-DECODED-REDEF REDEFINES EBCDIC-DECODED.
           05  ER-TYPE                 PIC X(1).
           05  ER-BODY                 PIC X(799).

           COPY "aud-write-api.cpy".

       01  WS-AUD-DISP               PIC ZZZZZZZZZZZZZZ9.

       01  WS-REASON-EXPANDED        PIC X(60).

       LINKAGE SECTION.
           COPY "inti-api.cpy".

       PROCEDURE DIVISION USING INTI-INPUT INTI-OUTPUT.
       MAIN-LOGIC.
           PERFORM INIT-OUTPUT
           PERFORM VALIDATE-INPUT
           IF NOT INTI-OK
               GOBACK
           END-IF
           PERFORM CHECK-SENTINEL
           IF INTI-NO-INPUT-READY
               GOBACK
           END-IF
           PERFORM OPEN-FILES
           IF NOT INTI-OK
               PERFORM CLEANUP
               GOBACK
           END-IF
           PERFORM EMIT-AUDIT-START
           PERFORM PROCESS-EBCDIC-LOOP
           PERFORM VERIFY-TRAILER
           PERFORM FINALIZE-OUTPUT
           PERFORM EMIT-AUDIT-END
           PERFORM POPULATE-OUTPUT
           PERFORM CLEANUP
           GOBACK.

       INIT-OUTPUT.
           SET INTI-OK TO TRUE
           MOVE 0 TO INTI-OUT-RECORDS-READ
                     INTI-OUT-DETAILS-DECODED
                     INTI-OUT-DETAILS-REJECTED
                     INTI-OUT-REJECT-PCT
                     INTI-OUT-DURATION-SEC
                     WS-CTR-READ WS-CTR-DECODED WS-CTR-REJECTED
                     WS-CHECKSUM-ACC
           MOVE "Y" TO INTI-OUT-CHECKSUM-MATCH
           MOVE "N" TO WS-EOF-FLAG WS-OUT-OPEN WS-REJ-OPEN WS-IN-OPEN
                       WS-HEADER-SEEN WS-TRAILER-SEEN WS-THRESHOLD-BREACH
           MOVE "Y" TO WS-CHECKSUM-MATCH-FLAG
           MOVE INTI-INPUT-FILENAME  TO WS-INPUT-PATH
           MOVE INTI-OUTPUT-FILENAME TO WS-OUTPUT-PATH
           MOVE INTI-REJECT-FILENAME TO WS-REJECT-PATH.

       VALIDATE-INPUT.
           IF INTI-BATCH-ID = SPACES OR
              INTI-BUSINESS-DATE = 0 OR
              INTI-INPUT-FILENAME = SPACES OR
              INTI-OUTPUT-FILENAME = SPACES
               SET INTI-INVALID-INPUT TO TRUE
           END-IF.

       CHECK-SENTINEL.
           IF NOT INTI-SENTINEL-YES
               EXIT PARAGRAPH
           END-IF
           IF INTI-SENTINEL-FILENAME = SPACES
               EXIT PARAGRAPH
           END-IF
           MOVE SPACES TO WS-CMD
           STRING "test -f " FUNCTION TRIM(INTI-SENTINEL-FILENAME)
                  DELIMITED BY SIZE INTO WS-CMD
           CALL "SYSTEM" USING WS-CMD
           IF RETURN-CODE NOT = 0
               SET INTI-NO-INPUT-READY TO TRUE
           END-IF.

       OPEN-FILES.
           OPEN INPUT EBCDIC-FILE
           IF WS-FS-IN NOT = "00"
               SET INTI-IO-FAIL TO TRUE
               EXIT PARAGRAPH
           END-IF
           MOVE "Y" TO WS-IN-OPEN
           OPEN OUTPUT DECODED-FILE
           IF WS-FS-OUT NOT = "00"
               SET INTI-IO-FAIL TO TRUE
               EXIT PARAGRAPH
           END-IF
           MOVE "Y" TO WS-OUT-OPEN
           OPEN OUTPUT REJECT-FILE
           IF WS-FS-REJ NOT = "00"
               SET INTI-IO-FAIL TO TRUE
               EXIT PARAGRAPH
           END-IF
           MOVE "Y" TO WS-REJ-OPEN.

       PROCESS-EBCDIC-LOOP.
           PERFORM READ-ONE-RECORD
           PERFORM UNTIL WS-EOF
               ADD 1 TO WS-CTR-READ
               PERFORM DECODE-EBCDIC-RECORD
               EVALUATE WS-CURRENT-TYPE
                   WHEN "H" PERFORM HANDLE-HEADER
                   WHEN "D" PERFORM HANDLE-DETAIL
                   WHEN "T" PERFORM HANDLE-TRAILER
                   WHEN OTHER
                       PERFORM REJECT-CURRENT
               END-EVALUATE
               PERFORM READ-ONE-RECORD
           END-PERFORM.

       READ-ONE-RECORD.
           READ EBCDIC-FILE
               AT END SET WS-EOF TO TRUE
           END-READ.

       DECODE-EBCDIC-RECORD.
           MOVE EBCDIC-IN-REC TO ED-WORK-REC
           MOVE EBCDIC-IN-REC TO WS-DECODED-BUF(1:800)
           MOVE WS-DECODED-BUF(1:1) TO WS-CURRENT-TYPE.

       HANDLE-HEADER.
           IF WS-HEADER-SEEN = "Y"
               MOVE "E102" TO WS-CURRENT-REASON
               PERFORM REJECT-CURRENT
               EXIT PARAGRAPH
           END-IF
           MOVE "Y" TO WS-HEADER-SEEN
           PERFORM BUILD-OUTPUT-HEADER
           PERFORM ACCUMULATE-CHECKSUM.

       BUILD-OUTPUT-HEADER.
           MOVE SPACES TO DECODED-OUT-REC
           MOVE "H"                  TO TDH-REC-TYPE
           MOVE INTI-BATCH-ID        TO TDH-BATCH-ID
           MOVE INTI-BUSINESS-DATE   TO TDH-BUSINESS-DATE
           MOVE "EBCDIC_BATCH"       TO TDH-SOURCE-SYSTEM
           MOVE 0                    TO TDH-EXPECTED-COUNT
           MOVE SPACES               TO TDH-CHECKSUM
           WRITE DECODED-OUT-REC FROM TXN-DECODED-REC.

       HANDLE-DETAIL.
           IF WS-HEADER-SEEN = "N"
               MOVE "E101" TO WS-CURRENT-REASON
               PERFORM REJECT-CURRENT
               EXIT PARAGRAPH
           END-IF
           PERFORM PARSE-DETAIL-FIELDS
           PERFORM TRANSLATE-CAT
           IF WS-CURRENT-REASON NOT = SPACES
               PERFORM REJECT-CURRENT
               EXIT PARAGRAPH
           END-IF
           PERFORM TRANSLATE-DATE
           IF WS-CURRENT-REASON NOT = SPACES
               PERFORM REJECT-CURRENT
               EXIT PARAGRAPH
           END-IF
           PERFORM VALIDATE-AMOUNT
           IF WS-CURRENT-REASON NOT = SPACES
               PERFORM REJECT-CURRENT
               EXIT PARAGRAPH
           END-IF
           PERFORM CHECK-ACCT-FORMAT
           IF WS-CURRENT-REASON NOT = SPACES
               PERFORM REJECT-CURRENT
               EXIT PARAGRAPH
           END-IF
           PERFORM WRITE-DECODED-DETAIL
           PERFORM ACCUMULATE-CHECKSUM
           ADD 1 TO WS-CTR-DECODED.

       PARSE-DETAIL-FIELDS.
           MOVE SPACES TO WS-CURRENT-REASON
           MOVE FUNCTION NUMVAL(WS-DECODED-BUF(2:4))
                                              TO WS-CURRENT-BANK
           MOVE FUNCTION NUMVAL(WS-DECODED-BUF(6:3))
                                              TO WS-CURRENT-BRANCH
           MOVE FUNCTION NUMVAL(WS-DECODED-BUF(9:2))
                                              TO WS-CURRENT-CAT-IN
           MOVE FUNCTION NUMVAL(WS-DECODED-BUF(11:15))
                                              TO WS-CURRENT-AMOUNT
           MOVE WS-DECODED-BUF(26:13)         TO WS-CURRENT-PAYER-ACCT
           MOVE WS-DECODED-BUF(39:13)         TO WS-CURRENT-PAYEE-ACCT
           MOVE WS-DECODED-BUF(52:120)        TO WS-CURRENT-DESC
           MOVE FUNCTION NUMVAL(WS-DECODED-BUF(172:10))
                                              TO WS-CURRENT-SEQ
           MOVE FUNCTION NUMVAL(WS-DECODED-BUF(182:3))
                                              TO WS-CURRENT-BRANCH
           MOVE FUNCTION NUMVAL(WS-DECODED-BUF(185:3))
                                              TO WS-CURRENT-PRODUCT
           MOVE FUNCTION NUMVAL(WS-DECODED-BUF(188:2))
                                              TO WS-CURRENT-DATE-YY
           MOVE FUNCTION NUMVAL(WS-DECODED-BUF(190:2))
                                              TO WS-CURRENT-DATE-MM
           MOVE FUNCTION NUMVAL(WS-DECODED-BUF(192:2))
                                              TO WS-CURRENT-DATE-DD.

       TRANSLATE-CAT.
           EVALUATE WS-CURRENT-CAT-IN
               WHEN 10 MOVE "10" TO WS-CURRENT-CAT-OUT
               WHEN 20 MOVE "20" TO WS-CURRENT-CAT-OUT
               WHEN 30 MOVE "30" TO WS-CURRENT-CAT-OUT
               WHEN 40 MOVE "40" TO WS-CURRENT-CAT-OUT
               WHEN OTHER MOVE "E105" TO WS-CURRENT-REASON
           END-EVALUATE.

       TRANSLATE-DATE.
           IF WS-CURRENT-DATE-YY < 50
               COMPUTE WS-CURRENT-DATE-YYYY =
                   (2000 + WS-CURRENT-DATE-YY) * 10000 +
                   WS-CURRENT-DATE-MM * 100 +
                   WS-CURRENT-DATE-DD
           ELSE
               COMPUTE WS-CURRENT-DATE-YYYY =
                   (1900 + WS-CURRENT-DATE-YY) * 10000 +
                   WS-CURRENT-DATE-MM * 100 +
                   WS-CURRENT-DATE-DD
           END-IF
           IF WS-CURRENT-DATE-MM = 0 OR WS-CURRENT-DATE-MM > 12 OR
              WS-CURRENT-DATE-DD = 0 OR WS-CURRENT-DATE-DD > 31
               MOVE "E110" TO WS-CURRENT-REASON
           END-IF.

       VALIDATE-AMOUNT.
           IF WS-CURRENT-AMOUNT = 0
               MOVE "E108" TO WS-CURRENT-REASON
               EXIT PARAGRAPH
           END-IF.

       CHECK-ACCT-FORMAT.
           IF WS-CURRENT-PAYER-ACCT(1:13) IS NOT NUMERIC
               MOVE "E106" TO WS-CURRENT-REASON
           END-IF.

       WRITE-DECODED-DETAIL.
           MOVE SPACES TO DECODED-OUT-REC
           MOVE "D"                  TO TDD-REC-TYPE
           MOVE WS-CURRENT-SEQ       TO TDD-SEQ
           MOVE WS-CURRENT-CAT-OUT   TO TDD-CATEGORY
           MOVE WS-CURRENT-AMOUNT    TO TDD-AMOUNT-JPY
           MOVE "JPY"                TO TDD-CURRENCY
           MOVE WS-CURRENT-PAYER-ACCT TO TDD-PAYER-ACCT
           MOVE WS-CURRENT-PAYEE-ACCT TO TDD-PAYEE-ACCT
           MOVE WS-CURRENT-BRANCH    TO TDD-BRANCH-CODE
           MOVE WS-CURRENT-PRODUCT   TO TDD-PRODUCT-CODE
           MOVE WS-CURRENT-DESC      TO TDD-DESCRIPTION
           MOVE WS-CURRENT-BANK      TO TDD-SOURCE-BANK
           MOVE WS-CURRENT-BRANCH    TO TDD-SOURCE-BRANCH
           MOVE WS-CURRENT-SEQ       TO TDD-ORIGINAL-SEQ
           WRITE DECODED-OUT-REC FROM TXN-DECODED-REC.

       ACCUMULATE-CHECKSUM.
           PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL WS-IDX > 800
               MOVE WS-DECODED-BUF(WS-IDX:1) TO WS-BYTE-CHAR
               MOVE FUNCTION ORD(WS-BYTE-CHAR) TO WS-BYTE-VAL
               ADD WS-BYTE-VAL TO WS-CHECKSUM-ACC
           END-PERFORM
           COMPUTE WS-CHECKSUM-ACC =
               FUNCTION MOD(WS-CHECKSUM-ACC, 65536).

       HANDLE-TRAILER.
           IF WS-HEADER-SEEN = "N"
               MOVE "E101" TO WS-CURRENT-REASON
               PERFORM REJECT-CURRENT
               EXIT PARAGRAPH
           END-IF
           MOVE "Y" TO WS-TRAILER-SEEN
           MOVE FUNCTION NUMVAL(WS-DECODED-BUF(2:10)) TO WS-T-RECORD-COUNT
           MOVE WS-DECODED-BUF(32:40) TO WS-T-CHECKSUM.

       VERIFY-TRAILER.
           IF WS-TRAILER-SEEN = "N"
               MOVE "E102" TO WS-CURRENT-REASON
               MOVE 0 TO WS-CHECKSUM-OUT
               PERFORM WRITE-REJECT-LINE
               SET INTI-PARTIAL TO TRUE
               EXIT PARAGRAPH
           END-IF
           IF WS-T-RECORD-COUNT NOT = WS-CTR-DECODED
               MOVE "N" TO WS-CHECKSUM-MATCH-FLAG
               MOVE "E103" TO WS-CURRENT-REASON
               PERFORM WRITE-REJECT-LINE
               SET INTI-PARTIAL TO TRUE
           END-IF.

       REJECT-CURRENT.
           IF WS-CURRENT-REASON = SPACES
               MOVE "E199" TO WS-CURRENT-REASON
           END-IF
           PERFORM EXPAND-REASON
           PERFORM WRITE-REJECT-LINE
           ADD 1 TO WS-CTR-REJECTED
           MOVE SPACES TO WS-CURRENT-REASON.

       EXPAND-REASON.
           EVALUATE WS-CURRENT-REASON
               WHEN "E101" MOVE "missing header"        TO WS-REASON-EXPANDED
               WHEN "E102" MOVE "duplicate or missing trailer" TO WS-REASON-EXPANDED
               WHEN "E103" MOVE "trailer record count mismatch" TO WS-REASON-EXPANDED
               WHEN "E105" MOVE "invalid category"       TO WS-REASON-EXPANDED
               WHEN "E106" MOVE "invalid acct format"    TO WS-REASON-EXPANDED
               WHEN "E108" MOVE "zero amount"            TO WS-REASON-EXPANDED
               WHEN "E110" MOVE "invalid date"           TO WS-REASON-EXPANDED
               WHEN "E111" MOVE "non-printable UTF-8"    TO WS-REASON-EXPANDED
               WHEN OTHER  MOVE "other rejection"        TO WS-REASON-EXPANDED
           END-EVALUATE.

       WRITE-REJECT-LINE.
           IF WS-REJ-OPEN = "N"
               EXIT PARAGRAPH
           END-IF
           MOVE SPACES TO REJECT-LINE
           STRING WS-CURRENT-REASON " | "
                  WS-DECODED-BUF(1:80) " | "
                  FUNCTION TRIM(WS-REASON-EXPANDED)
                  DELIMITED BY SIZE INTO REJECT-LINE
           WRITE REJECT-LINE.

       FINALIZE-OUTPUT.
           IF WS-CTR-DECODED + WS-CTR-REJECTED > 0
               COMPUTE WS-REJECT-PCT =
                   WS-CTR-REJECTED * 100 /
                   (WS-CTR-DECODED + WS-CTR-REJECTED)
           END-IF
           IF WS-REJECT-PCT > INTI-REJECT-THRESHOLD-PCT
               MOVE "Y" TO WS-THRESHOLD-BREACH
               SET INTI-PARTIAL TO TRUE
           END-IF
           IF WS-CHECKSUM-MATCH-FLAG = "Y" AND
              WS-THRESHOLD-BREACH = "N"
               PERFORM WRITE-DECODED-TRAILER
           END-IF
           IF WS-THRESHOLD-BREACH = "Y" AND WS-OUT-OPEN = "Y"
               CLOSE DECODED-FILE
               MOVE "N" TO WS-OUT-OPEN
               MOVE SPACES TO WS-CMD
               STRING "rm -f " FUNCTION TRIM(WS-OUTPUT-PATH)
                      DELIMITED BY SIZE INTO WS-CMD
               CALL "SYSTEM" USING WS-CMD
           END-IF.

       WRITE-DECODED-TRAILER.
           MOVE SPACES TO DECODED-OUT-REC
           MOVE "T"                  TO TDT-REC-TYPE
           MOVE WS-CTR-DECODED       TO TDT-RECORD-COUNT
           MOVE 0                    TO TDT-AMOUNT-SUM
           MOVE SPACES               TO TDT-CHECKSUM
           MOVE WS-CHECKSUM-ACC      TO WS-CHECKSUM-OUT
           STRING WS-CHECKSUM-OUT
                  DELIMITED BY SIZE INTO TDT-CHECKSUM
           WRITE DECODED-OUT-REC FROM TXN-DECODED-REC.

       EMIT-AUDIT-START.
           MOVE "19-integrationin"   TO WS-AUD-SUBSYSTEM
           MOVE "BATCH_DECODE_START" TO WS-AUD-ACTION
           MOVE "SYSTEM"             TO WS-AUD-ACTOR
           MOVE "BATCH"              TO WS-AUD-TARGET-TYPE
           MOVE INTI-BATCH-ID        TO WS-AUD-TARGET-ID
           MOVE "I"                  TO WS-AUD-SEVERITY
           MOVE INTI-BUSINESS-DATE   TO WS-AUD-BUSINESS-DATE
           MOVE SPACES               TO WS-AUD-PAYLOAD-JSON
           STRING '{"batch":"' INTI-BATCH-ID '"}'
                  DELIMITED BY SIZE INTO WS-AUD-PAYLOAD-JSON
           CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC
               ON EXCEPTION CONTINUE
           END-CALL.

       EMIT-AUDIT-END.
           MOVE "19-integrationin"   TO WS-AUD-SUBSYSTEM
           IF WS-THRESHOLD-BREACH = "Y"
               MOVE "BATCH_DECODE_FAIL"  TO WS-AUD-ACTION
               MOVE "W"                  TO WS-AUD-SEVERITY
           ELSE
               MOVE "BATCH_DECODE_END"   TO WS-AUD-ACTION
               MOVE "I"                  TO WS-AUD-SEVERITY
           END-IF
           MOVE "SYSTEM"             TO WS-AUD-ACTOR
           MOVE "BATCH"              TO WS-AUD-TARGET-TYPE
           MOVE INTI-BATCH-ID        TO WS-AUD-TARGET-ID
           MOVE INTI-BUSINESS-DATE   TO WS-AUD-BUSINESS-DATE
           MOVE SPACES               TO WS-AUD-PAYLOAD-JSON
           MOVE WS-CTR-DECODED       TO WS-AUD-DISP
           STRING '{"decoded":"' FUNCTION TRIM(WS-AUD-DISP) '"}'
                  DELIMITED BY SIZE INTO WS-AUD-PAYLOAD-JSON
           CALL "AUD-WRITE" USING WS-AUD-ROW WS-AUD-RC
               ON EXCEPTION CONTINUE
           END-CALL.

       POPULATE-OUTPUT.
           MOVE WS-CTR-READ          TO INTI-OUT-RECORDS-READ
           MOVE WS-CTR-DECODED       TO INTI-OUT-DETAILS-DECODED
           MOVE WS-CTR-REJECTED      TO INTI-OUT-DETAILS-REJECTED
           MOVE WS-REJECT-PCT        TO INTI-OUT-REJECT-PCT
           MOVE WS-CHECKSUM-MATCH-FLAG TO INTI-OUT-CHECKSUM-MATCH.

       CLEANUP.
           IF WS-IN-OPEN = "Y"
               CLOSE EBCDIC-FILE
               MOVE "N" TO WS-IN-OPEN
           END-IF
           IF WS-OUT-OPEN = "Y"
               CLOSE DECODED-FILE
               MOVE "N" TO WS-OUT-OPEN
           END-IF
           IF WS-REJ-OPEN = "Y"
               CLOSE REJECT-FILE
               MOVE "N" TO WS-REJ-OPEN
           END-IF.

       END PROGRAM INTI-DECODE-BATCH.
