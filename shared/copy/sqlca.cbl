      *> ============================================================
      *> sqlca.cpy — SQL Communications Area for Open-COBOL-ESQL
      *>
      *> Free-format reimplementation of OCESQL's sqlca.cbl, which ships
      *> in fixed format and is therefore incompatible with our project-wide
      *> free-format mandate (AGENTS.md rule 1).
      *>
      *> Use:    EXEC SQL INCLUDE sqlca END-EXEC.
      *> Compile path: cobc -I shared/copy/ocesql ...
      *> (also still need -I /usr/local/share/open-cobol-esql/copy for headers
      *>  referenced by OCESQL-generated CALLs)
      *>
      *> Layout MUST match the OCESQL-shipped binary contract — do NOT change
      *> field offsets or PICs. Bumping OCESQL version may require re-checking.
      *>
      *> Source: /usr/local/share/open-cobol-esql/copy/sqlca.cbl @ OCESQL 1.4.0
      *> ============================================================
       01  SQLCA GLOBAL.
           05  SQLCAID               PIC X(8).
           05  SQLCABC               PIC S9(9) COMP-5.
           05  SQLCODE               PIC S9(9) COMP-5.
           05  SQLERRM.
               49  SQLERRML          PIC S9(4) COMP-5.
               49  SQLERRMC          PIC X(70).
           05  SQLERRP               PIC X(8).
           05  SQLERRD OCCURS 6 TIMES
                                     PIC S9(9) COMP-5.
           05  SQLWARN.
               10  SQLWARN0          PIC X(1).
               10  SQLWARN1          PIC X(1).
               10  SQLWARN2          PIC X(1).
               10  SQLWARN3          PIC X(1).
               10  SQLWARN4          PIC X(1).
               10  SQLWARN5          PIC X(1).
               10  SQLWARN6          PIC X(1).
               10  SQLWARN7          PIC X(1).
           05  SQLSTATE              PIC X(5).
