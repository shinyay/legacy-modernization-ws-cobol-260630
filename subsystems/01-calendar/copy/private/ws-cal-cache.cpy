       01  WS-CAL-CACHE.
           05  WS-CACHE-LOADED         PIC X    VALUE 'N'.
               88  WS-IS-LOADED               VALUE 'Y'.
           05  WS-CACHE-COUNT          PIC 9(5) VALUE ZERO.
           05  WS-CACHE-ENTRIES.
               10  WS-CAL-ENTRY OCCURS 1826 TIMES INDEXED BY WS-CAL-IDX.
                   15  WS-ENTRY-DATE         PIC 9(8).
                   15  WS-ENTRY-DAY-TYPE     PIC X(1).
                       88  WS-ENTRY-BUSINESS         VALUE "B".
                       88  WS-ENTRY-HOLIDAY          VALUE "H".
                       88  WS-ENTRY-WEEKEND          VALUE "W".
                   15  WS-ENTRY-HOLIDAY-NAME PIC X(40).
