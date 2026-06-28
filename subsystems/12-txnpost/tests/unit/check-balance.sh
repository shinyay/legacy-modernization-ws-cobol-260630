#!/usr/bin/env bash
export PGPASSWORD="${PGPASSWORD:-cobol}"
ACTUAL=$(psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -tA -c "SELECT balance_jpy FROM balances WHERE account_number='$1'")
if [ "$ACTUAL" = "$2" ]; then
  exit 0
else
  echo "balance mismatch acct=$1 expected=$2 actual=$ACTUAL" >&2
  exit 1
fi
