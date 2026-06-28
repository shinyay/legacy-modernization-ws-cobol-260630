#!/usr/bin/env bash
export PGPASSWORD="${PGPASSWORD:-cobol}"
TABLE=$1; MIN=$2; COL=$3; VAL=$4
SQL="SELECT count(*) FROM $TABLE"
[ -n "$COL" ] && SQL="$SQL WHERE TRIM(TRAILING FROM $COL)='$VAL'"
ACTUAL=$(psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -tA -c "$SQL")
[ "$ACTUAL" -ge "$MIN" ] && exit 0 || { echo "count too low table=$TABLE expected_min=$MIN actual=$ACTUAL where TRIM($COL)='$VAL'" >&2; exit 1; }
