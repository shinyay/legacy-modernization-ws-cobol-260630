#!/usr/bin/env bash
export PGPASSWORD="${PGPASSWORD:-cobol}"
ACTUAL=$(psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -tA -c "SELECT SUM(debit_jpy)+SUM(credit_jpy) FROM postings WHERE txn_id='$1'")
[ "$ACTUAL" = "$2" ] && exit 0 || { echo "sum mismatch txn=$1 expected=$2 actual=$ACTUAL" >&2; exit 1; }
