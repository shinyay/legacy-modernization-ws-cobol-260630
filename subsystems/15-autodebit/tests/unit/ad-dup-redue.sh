#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q"

$PSQL -c "UPDATE autodebit_schedules SET status='AC', next_due_date='2026-06-13' WHERE instruction_id LIKE 'AD-DUP-%'"
