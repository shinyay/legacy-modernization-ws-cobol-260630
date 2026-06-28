#!/usr/bin/env bash
set -e
HORIZON="${1:?horizon-date required (YYYY-MM-DD)}"
export PGPASSWORD="${PGPASSWORD:-cobol}"
PSQL="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -t -A"

PARTS=$($PSQL -c "
    SELECT inhrelid::regclass::text AS pn,
           pg_get_expr(c.relpartbound, c.oid) AS bound
    FROM pg_inherits i
    JOIN pg_class c ON c.oid = i.inhrelid
    WHERE inhparent = 'audit_log'::regclass
" | while IFS='|' read pname bound; do
    end_date=$(echo "$bound" | sed -nE "s/.*TO \('([0-9-]+)'\).*/\1/p")
    if [ -n "$end_date" ] && [ "$end_date" \< "$HORIZON" -o "$end_date" = "$HORIZON" ]; then
        echo "$pname"
    fi
done)

count=0
for pn in $PARTS; do
    if $PSQL -v pn="$pn" <<'SQL' > /dev/null 2>&1
ALTER TABLE audit_log DETACH PARTITION :"pn";
SQL
    then
        echo "$pn"
        count=$((count + 1))
    fi
done

exit 0
