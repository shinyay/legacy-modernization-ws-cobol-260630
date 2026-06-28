       01  CAL-INPUT.
           05  CAL-INPUT-DATE         PIC 9(8).

       01  CAL-OUTPUT.
           05  CAL-STATUS             PIC 9(2).
               88  CAL-STATUS-OK              VALUE 00.
               88  CAL-STATUS-NOT-FOUND       VALUE 04.
               88  CAL-STATUS-INVALID-DATE    VALUE 08.
               88  CAL-STATUS-CACHE-FAIL      VALUE 12.
               88  CAL-STATUS-FATAL           VALUE 16.
           05  CAL-OUTPUT-DAY-TYPE    PIC X(1).
               88  CAL-DAY-BUSINESS           VALUE "B".
               88  CAL-DAY-HOLIDAY            VALUE "H".
               88  CAL-DAY-WEEKEND            VALUE "W".
           05  CAL-OUTPUT-HOLIDAY-NAME PIC X(40).
           05  CAL-OUTPUT-NEXT-DATE   PIC 9(8).
