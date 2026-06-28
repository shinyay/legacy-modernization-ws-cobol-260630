#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -t -A -q"
count=$($PSQL -c "SELECT COUNT(*) FROM audit_log WHERE TRIM(TRAILING FROM subsystem)='17-statement' AND business_date='2026-06-13'")
if [ "$count" -ge 2 ]; then
    exit 0
else
    echo "audit count=$count (expected >= 2)"
    exit 1
fi
