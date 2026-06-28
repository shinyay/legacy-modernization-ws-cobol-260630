       IDENTIFICATION DIVISION.
       PROGRAM-ID. BR-LIST-BY-REGION.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT BRANCH-FILE
               ASSIGN TO "/workspace/subsystems/02-branch/data/branch.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS BR-REC-CODE
               ALTERNATE RECORD KEY IS BR-REC-REGION WITH DUPLICATES
               FILE STATUS IS WS-FS.

       DATA DIVISION.
       FILE SECTION.
       COPY "fd-branch.cpy".

       WORKING-STORAGE SECTION.
       01  WS-FS              PIC X(2).
       01  WS-OPEN-FLAG       PIC X VALUE 'N'.
       01  WS-CURRENT-REGION  PIC X(20) VALUE SPACES.

       LINKAGE SECTION.
       COPY "br-api.cpy".

       PROCEDURE DIVISION USING BR-INPUT BR-OUTPUT.
       MAIN-LOGIC.
           MOVE 00 TO BR-OUT-STATUS

           IF WS-OPEN-FLAG = 'N' THEN
               OPEN INPUT BRANCH-FILE
               IF WS-FS NOT = "00"
                   MOVE 16 TO BR-OUT-STATUS GOBACK
               END-IF
               MOVE 'Y' TO WS-OPEN-FLAG
           END-IF

           IF BR-IN-OP = "R" THEN
               MOVE BR-IN-REGION TO BR-REC-REGION
               MOVE BR-IN-REGION TO WS-CURRENT-REGION
               START BRANCH-FILE KEY = BR-REC-REGION
                   INVALID KEY
                       MOVE 10 TO BR-OUT-STATUS GOBACK
               END-START
           END-IF

           READ BRANCH-FILE NEXT
               AT END
                   MOVE 10 TO BR-OUT-STATUS GOBACK
               NOT AT END
                   IF BR-REC-REGION NOT = WS-CURRENT-REGION
                       MOVE 10 TO BR-OUT-STATUS GOBACK
                   END-IF
                   MOVE BR-REC-CODE        TO BR-OUT-CODE
                   MOVE BR-REC-NAME-KANJI  TO BR-OUT-NAME-KANJI
                   MOVE BR-REC-NAME-KANA   TO BR-OUT-NAME-KANA
                   MOVE BR-REC-REGION      TO BR-OUT-REGION
                   MOVE BR-REC-STATUS      TO BR-OUT-STATUS-CODE
                   MOVE 00 TO BR-OUT-STATUS
           END-READ
           GOBACK.
