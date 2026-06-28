       01  ALC-OPEN-INPUT.
           05  ALC-OPEN-CUST-ID         PIC 9(10).
           05  ALC-OPEN-PRODUCT-CODE    PIC 9(3).
           05  ALC-OPEN-BRANCH-CODE     PIC 9(3).
           05  ALC-OPEN-OPENED-DATE     PIC 9(8).
           05  ALC-OPEN-OVERDRAFT-LIMIT PIC S9(15) COMP-3.
           05  ALC-OPEN-TERM-DAYS       PIC 9(4).

       01  ALC-OPEN-OUTPUT.
           05  ALC-OPEN-ACCT-NUMBER     PIC 9(13).

       01  ALC-OPEN-STATUS              PIC X(2).
           88  ALC-OPEN-OK                          VALUE "00".
           88  ALC-OPEN-NOT-FOUND                   VALUE "04".
           88  ALC-OPEN-INVALID                     VALUE "08".
           88  ALC-OPEN-IO-FAIL                     VALUE "12".
           88  ALC-OPEN-FATAL                       VALUE "16".

       01  ALC-CHANGE-INPUT.
           05  ALC-CHANGE-ACCT-NUMBER   PIC 9(13).
           05  ALC-CHANGE-ACTION-CODE   PIC X(2).
               88  ALC-ACT-ACTIVATE                 VALUE "AC".
               88  ALC-ACT-CANCEL                   VALUE "CN".
               88  ALC-ACT-SUSPEND                  VALUE "SU".
               88  ALC-ACT-LIFT-SUSPEND             VALUE "LS".
               88  ALC-ACT-CLOSE                    VALUE "CL".
               88  ALC-ACT-FORCE-CLOSE              VALUE "FC".
           05  ALC-CHANGE-REASON-TEXT   PIC X(80).
           05  ALC-CHANGE-BUSINESS-DATE PIC 9(8).

       01  ALC-CHANGE-OUTPUT.
           05  ALC-CHANGE-FROM-STATUS   PIC X(1).
           05  ALC-CHANGE-TARGET-STATUS PIC X(1).

       01  ALC-CHANGE-STATUS            PIC X(2).
           88  ALC-CHANGE-OK                        VALUE "00".
           88  ALC-CHANGE-NOT-FOUND                 VALUE "04".
           88  ALC-CHANGE-INVALID                   VALUE "08".
           88  ALC-CHANGE-IO-FAIL                   VALUE "12".
           88  ALC-CHANGE-FATAL                     VALUE "16".

       01  ALC-DORMANCY-SCAN-INPUT.
           05  ALC-DORMANCY-BUSINESS-DATE PIC 9(8).

       01  ALC-DORMANCY-SCAN-OUTPUT.
           05  ALC-DORMANCY-TRANSITIONED PIC 9(6).
           05  ALC-DORMANCY-SKIPPED      PIC 9(6).

       01  ALC-DORMANCY-SCAN-STATUS     PIC X(2).
           88  ALC-DORM-SCAN-OK                     VALUE "00".
           88  ALC-DORM-SCAN-NO-CANDS               VALUE "04".
           88  ALC-DORM-SCAN-IO-FAIL                VALUE "12".
           88  ALC-DORM-SCAN-FATAL                  VALUE "16".

       01  ALC-REACTIVATION-SCAN-INPUT.
           05  ALC-REACT-BUSINESS-DATE  PIC 9(8).

       01  ALC-REACTIVATION-SCAN-OUTPUT.
           05  ALC-REACT-TRANSITIONED   PIC 9(6).
           05  ALC-REACT-SKIPPED        PIC 9(6).

       01  ALC-REACTIVATION-SCAN-STATUS PIC X(2).
           88  ALC-REACT-OK                         VALUE "00".
           88  ALC-REACT-NO-CANDS                   VALUE "04".
           88  ALC-REACT-IO-FAIL                    VALUE "12".
           88  ALC-REACT-FATAL                      VALUE "16".
