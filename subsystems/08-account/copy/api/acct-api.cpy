       01  ACCT-LOOKUP-INPUT.
           05  ACCT-LOOKUP-NUMBER          PIC 9(13).

       01  ACCT-LOOKUP-OUTPUT.
           05  ACCT-LO-NUMBER              PIC 9(13).
           05  ACCT-LO-CUST-ID             PIC 9(10).
           05  ACCT-LO-PRODUCT-CODE        PIC 9(3).
           05  ACCT-LO-BRANCH-CODE         PIC 9(3).
           05  ACCT-LO-OPENED-DATE         PIC 9(8).
           05  ACCT-LO-CLOSED-DATE         PIC 9(8).
           05  ACCT-LO-STATUS              PIC X(1).
               88  ACCT-ST-APPLICATION                VALUE "P".
               88  ACCT-ST-ACTIVE                     VALUE "A".
               88  ACCT-ST-DORMANT                    VALUE "D".
               88  ACCT-ST-SUSPENDED                  VALUE "S".
               88  ACCT-ST-CLOSED                     VALUE "C".
               88  ACCT-ST-REACTIVATING               VALUE "R".
           05  ACCT-LO-OVERDRAFT-LIMIT     PIC S9(15) COMP-3.
           05  ACCT-LO-TERM-DAYS           PIC 9(4).
           05  ACCT-LO-DORMANCY-DATE       PIC 9(8).
           05  ACCT-LO-CREATED-TS          PIC 9(14).
           05  ACCT-LO-UPDATED-TS          PIC 9(14).
           05  ACCT-LO-FILLER              PIC X(6).

       01  ACCT-LOOKUP-STATUS              PIC X(2).
           88  ACCT-LOOKUP-OK                          VALUE "00".
           88  ACCT-LOOKUP-NOT-FOUND                   VALUE "04".
           88  ACCT-LOOKUP-INVALID-INPUT               VALUE "08".
           88  ACCT-LOOKUP-IO-FAIL                     VALUE "12".
           88  ACCT-LOOKUP-FATAL                       VALUE "16".

       01  ACCT-EXISTS-INPUT.
           05  ACCT-EXISTS-NUMBER          PIC 9(13).

       01  ACCT-EXISTS-OUTPUT.
           05  ACCT-EXISTS-FOUND           PIC X(1).
               88  ACCT-EXISTS-YES                    VALUE "Y".
               88  ACCT-EXISTS-NO                     VALUE "N".
           05  ACCT-EXISTS-STATUS-CODE     PIC X(1).
           05  ACCT-EXISTS-PRODUCT-CODE    PIC 9(3).
           05  ACCT-EXISTS-ACTIVE-FLAG     PIC X(1).
               88  ACCT-EXISTS-ACTIVE                 VALUE "Y".
               88  ACCT-EXISTS-NOT-ACTIVE             VALUE "N".
           05  ACCT-EXISTS-FILLER          PIC X(2).

       01  ACCT-EXISTS-API-STATUS          PIC X(2).
           88  ACCT-EXISTS-OK                         VALUE "00".
           88  ACCT-EXISTS-NOT-FOUND-RC               VALUE "04".
           88  ACCT-EXISTS-INVALID                    VALUE "08".
           88  ACCT-EXISTS-IO-FAIL                    VALUE "12".
           88  ACCT-EXISTS-FATAL                      VALUE "16".

       01  ACCT-LOOKUP-BY-CUST-INPUT.
           05  LOOKUP-BY-CUST-CUST-ID      PIC 9(10).
           05  LOOKUP-BY-CUST-MAX          PIC 9(2) COMP-3.
           05  LOOKUP-BY-CUST-START-AFTER  PIC 9(13).

       01  ACCT-LOOKUP-BY-CUST-OUTPUT.
           05  LOOKUP-BY-CUST-COUNT        PIC 9(2) COMP-3.
           05  LOOKUP-BY-CUST-MORE         PIC X(1).
               88  LOOKUP-BY-CUST-MORE-YES            VALUE "Y".
               88  LOOKUP-BY-CUST-MORE-NO             VALUE "N".
           05  LOOKUP-BY-CUST-LAST-ACCT    PIC 9(13).
           05  LOOKUP-BY-CUST-RECORDS      OCCURS 20 TIMES.
               10  LOOKUP-BY-CUST-REC      PIC X(100).

       01  ACCT-LOOKUP-BY-CUST-STATUS      PIC X(2).
           88  LBC-OK                                  VALUE "00".
           88  LBC-DUP-WARN                            VALUE "02".
           88  LBC-NOT-FOUND                           VALUE "04".
           88  LBC-INVALID                             VALUE "08".
           88  LBC-IO-FAIL                             VALUE "12".
           88  LBC-FATAL                               VALUE "16".

       01  ACCT-UPDATE-DORMANCY-INPUT.
           05  UPDATE-DORMANCY-ACCT-NUMBER PIC 9(13).
           05  UPDATE-DORMANCY-NEW-DATE    PIC 9(8).

       01  ACCT-UPDATE-DORMANCY-OUTPUT.
           05  UPDATE-DORMANCY-PREV-DATE   PIC 9(8).
           05  UPDATE-DORMANCY-WAS-NOOP    PIC X(1).
               88  DORMANCY-NOOP-Y                    VALUE "Y".
               88  DORMANCY-NOOP-N                    VALUE "N".
           05  UPDATE-DORMANCY-FILLER      PIC X(1).

       01  ACCT-UPDATE-DORMANCY-STATUS     PIC X(2).
           88  UPDATE-DORM-OK                          VALUE "00".
           88  UPDATE-DORM-NOT-FOUND                   VALUE "04".
           88  UPDATE-DORM-INVALID                     VALUE "08".
           88  UPDATE-DORM-IO-FAIL                     VALUE "12".
           88  UPDATE-DORM-FATAL                       VALUE "16".
