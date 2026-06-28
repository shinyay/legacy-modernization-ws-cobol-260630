       IDENTIFICATION DIVISION.
       PROGRAM-ID. BR-LOOKUP.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT BRANCH-FILE
               ASSIGN TO "/workspace/subsystems/02-branch/data/branch.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS BR-REC-CODE
               ALTERNATE RECORD KEY IS BR-REC-REGION WITH DUPLICATES
               FILE STATUS IS WS-FS.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-branch.cpy".

       WORKING-STORAGE SECTION.
       01  WS-FS              PIC X(2).
       01  WS-OPENED-FLAG     PIC X VALUE 'N'.

       LINKAGE SECTION.
       COPY "br-api.cpy".

       PROCEDURE DIVISION USING BR-INPUT BR-OUTPUT.
       MAIN-LOGIC.
           MOVE 00 TO BR-OUT-STATUS
           MOVE SPACES TO BR-OUT-CODE BR-OUT-NAME-KANJI
                          BR-OUT-NAME-KANA BR-OUT-REGION

           IF WS-OPENED-FLAG = 'N' THEN
               OPEN INPUT BRANCH-FILE
               IF WS-FS NOT = "00"
                   MOVE 16 TO BR-OUT-STATUS GOBACK
               END-IF
               MOVE 'Y' TO WS-OPENED-FLAG
           END-IF

           MOVE BR-IN-CODE TO BR-REC-CODE
           READ BRANCH-FILE
               INVALID KEY
                   MOVE 04 TO BR-OUT-STATUS
                   GOBACK
               NOT INVALID KEY
                   MOVE BR-REC-CODE        TO BR-OUT-CODE
                   MOVE BR-REC-NAME-KANJI  TO BR-OUT-NAME-KANJI
                   MOVE BR-REC-NAME-KANA   TO BR-OUT-NAME-KANA
                   MOVE BR-REC-REGION      TO BR-OUT-REGION
                   MOVE BR-REC-STATUS      TO BR-OUT-STATUS-CODE
                   MOVE 00 TO BR-OUT-STATUS
           END-READ
           GOBACK.
