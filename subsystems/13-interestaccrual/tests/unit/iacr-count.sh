#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -tA"
BDATE="$1"
STATUS="${2:-}"
SQL="SELECT count(*) FROM interest_accruals WHERE business_date='$BDATE' AND account_number LIKE '001001009%'"
if [ -n "$STATUS" ]; then
  SQL="$SQL AND status='$STATUS'"
fi
$PSQL -c "$SQL"
