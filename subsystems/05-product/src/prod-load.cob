       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROD-LOAD.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PRD-SEED-FILE
               ASSIGN TO "/workspace/subsystems/05-product/data/products-mvp.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-SEED-FS.
           SELECT PRODUCT-FILE
               ASSIGN TO "/workspace/subsystems/05-product/data/product.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS PRD-REC-CODE
               FILE STATUS IS WS-IDX-FS.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-prd-seed.cpy".
       COPY "fd-product.cpy".

       WORKING-STORAGE SECTION.
       01  WS-SEED-FS PIC X(2).
       01  WS-IDX-FS  PIC X(2).
       01  WS-EOF     PIC X VALUE 'N'. 88 EOFY VALUE 'Y'.
       01  WS-COUNT   PIC 9(3) VALUE 0.
       01  WS-DUP     PIC 9(3) VALUE 0.
       COPY "shared-log-api.cpy".

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           OPEN INPUT PRD-SEED-FILE
           OPEN OUTPUT PRODUCT-FILE
           IF WS-SEED-FS NOT = "00" OR WS-IDX-FS NOT = "00"
               MOVE 16 TO RETURN-CODE GOBACK
           END-IF

           PERFORM UNTIL EOFY
               READ PRD-SEED-FILE
                   AT END SET EOFY TO TRUE
                   NOT AT END
                       MOVE PS-CODE        TO PRD-REC-CODE
                       MOVE PS-NAME-KANJI  TO PRD-REC-NAME-KANJI
                       MOVE PS-NAME-KANA   TO PRD-REC-NAME-KANA
                       MOVE PS-TYPE        TO PRD-REC-TYPE
                       MOVE PS-INTEREST    TO PRD-REC-INTEREST
                       MOVE PS-OVD         TO PRD-REC-OVD
                       MOVE PS-MIN-BAL     TO PRD-REC-MIN-BAL
                       MOVE PS-TERM-DAYS   TO PRD-REC-TERM-DAYS
                       MOVE PS-EFF-FROM    TO PRD-REC-EFF-FROM
                       MOVE PS-EFF-TO      TO PRD-REC-EFF-TO
                       MOVE PS-FILLER      TO PRD-REC-FILLER
                       WRITE PRD-REC
                           INVALID KEY ADD 1 TO WS-DUP
                           NOT INVALID KEY ADD 1 TO WS-COUNT
                       END-WRITE
               END-READ
           END-PERFORM

           CLOSE PRD-SEED-FILE
           CLOSE PRODUCT-FILE

           MOVE "05-product" TO WS-LOG-SUBSYSTEM
           MOVE "INFO " TO WS-LOG-LEVEL
           STRING "PROD-LOAD complete loaded=" WS-COUNT
                  INTO WS-LOG-MESSAGE END-STRING
           CALL "SHARED-LOG" USING WS-LOG-MSG WS-LOG-RC

           MOVE 0 TO RETURN-CODE
           STOP RUN.
