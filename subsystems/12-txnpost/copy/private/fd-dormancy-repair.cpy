       FD  DORMANCY-REPAIR-FILE.
       01  DRMR-REC.
           05  DRMR-ACCT-NUMBER         PIC 9(13).
           05  DRMR-BUSINESS-DATE       PIC 9(8).
           05  DRMR-ATTEMPT-COUNT       PIC 9(2).
           05  DRMR-REASON-TEXT         PIC X(80).
           05  DRMR-SOURCE-BATCH-ID     PIC X(14).
           05  DRMR-CREATED-TS          PIC X(19).
