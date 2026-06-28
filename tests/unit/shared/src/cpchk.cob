IDENTIFICATION DIVISION.
PROGRAM-ID. CPCHK.

ENVIRONMENT DIVISION.
DATA DIVISION.
WORKING-STORAGE SECTION.

01 WS-DATE                    PIC 9(8) VALUE 20260611.
COPY "ws-date.cpy".

COPY "ws-date-validate.cpy".

COPY "shared-log-api.cpy".

COPY "aud-write-api.cpy".

COPY "ws-codes.cpy".

COPY "ebcdic-txn.cpy".

COPY "double-entry-helper.cpy".

PROCEDURE DIVISION.
MAIN-LOGIC.
    DISPLAY "[cpchk] All 7 directly-COPYable shared copybooks compiled OK.".
    DISPLAY "[cpchk]   1. ws-date.cpy                  -> WS-DATE-SUBFIELDS OK".
    DISPLAY "[cpchk]   2. ws-date-validate.cpy         -> WS-DATE-VALIDATE-WORK OK".
    DISPLAY "[cpchk]   3. std-header.cpy               -> SKIPPED (template only)".
    DISPLAY "[cpchk]   4. shared-log-api.cpy           -> WS-LOG-MSG OK".
    DISPLAY "[cpchk]   5. aud-write-api.cpy            -> WS-AUD-ROW OK".
    DISPLAY "[cpchk]   6. sqlca.cbl                    -> SKIPPED (OCESQL injects)".
    DISPLAY "[cpchk]   7. ws-codes.cpy                 -> WS-RC-CODES OK".
    DISPLAY "[cpchk]   8. ebcdic-txn.cpy               -> EBCDIC-REC OK".
    DISPLAY "[cpchk]   9. double-entry-helper.cpy      -> DEH-IN OK".
    DISPLAY "[cpchk] PASS.".
    STOP RUN.
