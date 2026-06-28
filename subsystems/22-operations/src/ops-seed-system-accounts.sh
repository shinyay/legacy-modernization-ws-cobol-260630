#!/usr/bin/env bash
set -euo pipefail

PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking}"
export PGPASSWORD="${PGPASSWORD:-cobol}"

echo "[ops-seed] start"

$PSQL -q <<'SQL'
INSERT INTO customers (cust_id, cust_name, cust_name_kana, cust_status, tier)
VALUES ('0000000001', 'PRACTICE BANK SYSTEM CUSTOMER', 'SYSTEM', 'A', 'B')
ON CONFLICT (cust_id) DO NOTHING;
SQL
echo "[ops-seed] SYSTEM CUST upserted"

SEEDED=0
for i in 1 2 3 4; do
  ACCT="001001000000$i"
  case $i in
    1) NAME="CASH SYSTEM ACCOUNT" ;;
    2) NAME="CLEARING SYSTEM ACCOUNT" ;;
    3) NAME="INTEREST EXPENSE ACCOUNT" ;;
    4) NAME="FEE REVENUE ACCOUNT" ;;
  esac
  $PSQL -q -v acct="$ACCT" -v name="$NAME" <<'SQL'
INSERT INTO accounts (acct_number, acct_name, branch_code, product_code, acct_status, cust_id, opened_date)
VALUES (:'acct', :'name', '001', '001', 'A', '0000000001', '2026-01-01')
ON CONFLICT (acct_number) DO NOTHING;
SQL
  SEEDED=$((SEEDED + 1))
done
echo "[ops-seed] system accts seeded/exists=$SEEDED"

BSEEDED=0
for i in 1 2 3 4; do
  ACCT="001001000000$i"
  $PSQL -q -v acct="$ACCT" <<'SQL'
INSERT INTO balances (account_number, balance_jpy, available_jpy, hold_jpy)
VALUES (:'acct', 0, 0, 0)
ON CONFLICT (account_number) DO NOTHING;
SQL
  BSEEDED=$((BSEEDED + 1))
done
echo "[ops-seed] system balances seeded/exists=$BSEEDED"

cobc -x -free -W -o /tmp/ops-seed-system-isam \
    /workspace/subsystems/22-operations/src/ops-seed-system-isam.cob \
    || { echo "[ops-seed] failed to compile ops-seed-system-isam" >&2 ; exit 1 ; }
/tmp/ops-seed-system-isam \
    || { echo "[ops-seed] ops-seed-system-isam returned non-zero" >&2 ; exit 1 ; }

echo "[ops-seed] complete"
