       FD  TXN-CHECKPOINT-FILE.
       01  TXN-CHECKPOINT-REC.
           05  TC-LAST-SEQ              PIC 9(10).
           05  TC-CHECKSUM              PIC X(8).
           05  TC-SENTINEL              PIC X(2).
