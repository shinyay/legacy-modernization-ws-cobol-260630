#!/usr/bin/env bash
set -e
SERIAL="${1:?serial required (e.g. 9999999999)}"
case "$SERIAL" in
  *[!0-9]*) echo "serial must be digits (e.g. 9999999999)" >&2; exit 2 ;;
esac
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q -tA"

SRCSEQ="${SERIAL: -9}"

BDATE_ISO="$(date +%Y-%m-%d)"
BDATEC="$(date +%Y%m%d)"

$PSQL -v ON_ERROR_STOP=1 -v serial="$SERIAL" -v srcseq="$SRCSEQ" \
      -v bdate="$BDATE_ISO" -v bdatec="$BDATEC" <<'SQL'
INSERT INTO transactions
  (txn_id, business_date, system_ts, category, account_number,
   amount_jpy, currency, source_system, source_batch_id, source_seq,
   status, reversal_of, created_by, created_ts)
VALUES
  (:'bdatec' || :'serial', :'bdate'::date, NOW(),
   '10', '0010010099001', 1000, 'JPY', 'TEST',
   'RV' || :'bdatec', :'srcseq'::int, 'RV',
   'RVDUMMYORIG0000001', 'TEST', NOW());
SQL
