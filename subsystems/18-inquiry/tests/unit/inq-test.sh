#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
export COB_LIBRARY_PATH="${COB_LIBRARY_PATH:-/workspace/subsystems/18-inquiry/bin}"
export LD_PRELOAD="${LD_PRELOAD:-/usr/local/lib/libocesql.so}"
export PGHOST="${PGHOST:-postgres}"
export PGUSER="${PGUSER:-cobol}"
export PGDATABASE="${PGDATABASE:-banking}"
export TERM="${TERM:-xterm-256color}"

INQ_BIN="/workspace/subsystems/18-inquiry/bin/inq"

bash /workspace/subsystems/18-inquiry/tests/unit/inq-setup-pg.sh > /dev/null

echo "=== 18-inquiry unit tests (Phase 6 Step 2) ==="

PASS=0
FAIL=0
N=0

run_tc() {
    local name="$1"
    local input="$2"
    local expect_pattern="$3"
    N=$((N+1))
    local output
    output=$(printf '%s\n' "$input" | $INQ_BIN --no-screen 2>&1 || true)
    if echo "$output" | grep -qE "$expect_pattern"; then
        PASS=$((PASS+1))
        printf "  [PASS] %03d %s\n" "$N" "$name"
    else
        FAIL=$((FAIL+1))
        printf "  [FAIL] %03d %s (pattern not found: %s)\n" "$N" "$name" "$expect_pattern"
        echo "    output: $(echo "$output" | head -3 | tr '\n' '|')"
    fi
}

run_tc "main menu shown" "0" "PRACTICE BANK INQUIRY TOOL"

run_tc "ACCT mode T1 found" \
    "1
0010010099501
0" \
    "0010010099501.*ACCOUNT|ACCOUNT.*0010010099501|Customer.*INQ"

run_tc "ACCT mode not found" \
    "1
0010010099999
0" \
    "Account not found"

run_tc "BAL mode T2 balance" \
    "5
0010010099502
0" \
    "Balance:"

run_tc "BAL T2 has 75000" \
    "5
0010010099502
0" \
    "75,000"

run_tc "TXN-HIST mode" \
    "4
0010010099501
0" \
    "TXN HISTORY"

run_tc "Help mode" \
    "9
0" \
    "INQUIRY HELP"

run_tc "Invalid menu choice" \
    "X
0" \
    "Invalid menu selection"

N=$((N+1))
prior_start_count=$(psql -h $PGHOST -U $PGUSER -d $PGDATABASE -t -A -c "SELECT COUNT(*) FROM audit_log WHERE TRIM(TRAILING FROM action)='INQ_SESSION_START'")
printf '%s\n' "0" | $INQ_BIN --no-screen > /dev/null 2>&1
new_start_count=$(psql -h $PGHOST -U $PGUSER -d $PGDATABASE -t -A -c "SELECT COUNT(*) FROM audit_log WHERE TRIM(TRAILING FROM action)='INQ_SESSION_START'")
if [ "$new_start_count" -gt "$prior_start_count" ]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d SESSION_START audit incremented\n" "$N"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d SESSION_START audit not incremented (%d -> %d)\n" "$N" "$prior_start_count" "$new_start_count"
fi

N=$((N+1))
prior_end_count=$(psql -h $PGHOST -U $PGUSER -d $PGDATABASE -t -A -c "SELECT COUNT(*) FROM audit_log WHERE TRIM(TRAILING FROM action)='INQ_SESSION_END'")
printf '%s\n' "0" | $INQ_BIN --no-screen > /dev/null 2>&1
new_end_count=$(psql -h $PGHOST -U $PGUSER -d $PGDATABASE -t -A -c "SELECT COUNT(*) FROM audit_log WHERE TRIM(TRAILING FROM action)='INQ_SESSION_END'")
if [ "$new_end_count" -gt "$prior_end_count" ]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d SESSION_END audit incremented\n" "$N"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d SESSION_END audit not incremented (%d -> %d)\n" "$N" "$prior_end_count" "$new_end_count"
fi

echo "=== Total: $N | PASS: $PASS | FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
