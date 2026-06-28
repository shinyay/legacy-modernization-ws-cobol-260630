       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROD-LOOKUP.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PRODUCT-FILE
               ASSIGN TO "/workspace/subsystems/05-product/data/product.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS PRD-REC-CODE
               FILE STATUS IS WS-FS.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-product.cpy".

       WORKING-STORAGE SECTION.
       01  WS-FS         PIC X(2).
       01  WS-OPEN-FLAG  PIC X VALUE 'N'.

       LINKAGE SECTION.
       COPY "prod-api.cpy".

       PROCEDURE DIVISION USING PROD-INPUT PROD-OUTPUT.
       MAIN-LOGIC.
           MOVE 0 TO PRD-OUT-STATUS
           MOVE SPACES TO PRD-OUT-CODE PRD-OUT-NAME
                          PRD-OUT-TYPE PRD-OUT-INTEREST-TYPE
                          PRD-OUT-ALLOW-OVD
           MOVE 0 TO PRD-OUT-TERM-DAYS
           MOVE 0 TO PRD-OUT-EFF-FROM PRD-OUT-EFF-TO

           IF WS-OPEN-FLAG = 'N'
               OPEN INPUT PRODUCT-FILE
               IF WS-FS NOT = "00" MOVE 16 TO PRD-OUT-STATUS GOBACK END-IF
               MOVE 'Y' TO WS-OPEN-FLAG
           END-IF

           MOVE PRD-IN-CODE TO PRD-REC-CODE
           READ PRODUCT-FILE
               INVALID KEY MOVE 4 TO PRD-OUT-STATUS GOBACK
               NOT INVALID KEY
                   MOVE PRD-REC-CODE       TO PRD-OUT-CODE
                   MOVE PRD-REC-NAME-KANJI TO PRD-OUT-NAME
                   MOVE PRD-REC-TYPE       TO PRD-OUT-TYPE
                   MOVE PRD-REC-INTEREST   TO PRD-OUT-INTEREST-TYPE
                   MOVE PRD-REC-OVD        TO PRD-OUT-ALLOW-OVD
                   MOVE PRD-REC-TERM-DAYS  TO PRD-OUT-TERM-DAYS
                   MOVE PRD-REC-EFF-FROM   TO PRD-OUT-EFF-FROM
                   MOVE PRD-REC-EFF-TO     TO PRD-OUT-EFF-TO
                   MOVE 0 TO PRD-OUT-STATUS
           END-READ
           GOBACK.
