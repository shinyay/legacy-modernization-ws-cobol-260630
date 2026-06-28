       FD  TXN-ERROR-FILE.
       01  TXN-ERROR-FD-REC.
           05  TEF-ORIG-SEQ             PIC 9(10).
           05  TEF-REASON-CODE          PIC X(4).
           05  TEF-REASON-TEXT          PIC X(80).
           05  TEF-ORIG-REC             PIC X(600).
