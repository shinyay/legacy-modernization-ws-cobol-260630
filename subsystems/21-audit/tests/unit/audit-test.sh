#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
export PGHOST="${PGHOST:-postgres}"
export PGUSER="${PGUSER:-cobol}"
export PGDATABASE="${PGDATABASE:-banking}"

DRIVER="/workspace/subsystems/21-audit/bin/audit-driver"
TMPDIR="/tmp/audit-test"
mkdir -p $TMPDIR

PASS=0
FAIL=0
N=0

echo "=== 21-audit unit tests (Phase 8) ==="

expect_pass() {
    local name="$1" expect_rc="$2"; shift 2
    N=$((N+1))
    local actual_rc=0
    "$@" > $TMPDIR/log.out 2>&1 || actual_rc=$?
    if [ "$actual_rc" = "$expect_rc" ]; then
        PASS=$((PASS+1))
        printf "  [PASS] %03d %s\n" "$N" "$name"
    else
        FAIL=$((FAIL+1))
        printf "  [FAIL] %03d %s (rc=%d expected %d)\n" "$N" "$name" "$actual_rc" "$expect_rc"
        head -5 $TMPDIR/log.out | sed 's/^/    /'
    fi
}

expect_pass "TC01 forensic date-range basic" 0 env \
    AUDIT_MODE=F \
    AUDIT_DATE_START=20260601 AUDIT_DATE_END=20260730 \
    AUDIT_OUT_FILE=$TMPDIR/tc01.txt AUDIT_FORMAT=TEXT \
    $DRIVER
N=$((N+1))
if [ -s $TMPDIR/tc01.txt ] && grep -q "Audit Forensic Result" $TMPDIR/tc01.txt; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d TC01 output non-empty + header\n" "$N"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d TC01 output missing/empty\n" "$N"
fi

expect_pass "TC02 subsystem=17-statement" 0 env \
    AUDIT_MODE=F \
    AUDIT_DATE_START=20260601 AUDIT_DATE_END=20260730 \
    AUDIT_SUBSYS="17-statement" \
    AUDIT_OUT_FILE=$TMPDIR/tc02.txt AUDIT_FORMAT=TEXT \
    $DRIVER
N=$((N+1))
rows=$(grep -cE "^[0-9]+ \|" $TMPDIR/tc02.txt 2>/dev/null | tr -d '[:space:]')
[ -z "$rows" ] && rows=0
if [ "$rows" -ge 1 ] && grep -q "17-statement" $TMPDIR/tc02.txt; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d TC02 17-statement rows=%d\n" "$N" "$rows"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d TC02 no 17-statement rows (got %d)\n" "$N" "$rows"
fi

expect_pass "TC03 action=STMT_GEN_END" 0 env \
    AUDIT_MODE=F \
    AUDIT_DATE_START=20260601 AUDIT_DATE_END=20260730 \
    AUDIT_ACTION="STMT_GEN_END" \
    AUDIT_OUT_FILE=$TMPDIR/tc03.txt AUDIT_FORMAT=TEXT \
    $DRIVER
N=$((N+1))
if grep -q "STMT_GEN_END" $TMPDIR/tc03.txt; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d TC03 action filter\n" "$N"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d TC03 no STMT_GEN_END rows\n" "$N"
fi

expect_pass "TC04 CSV format" 0 env \
    AUDIT_MODE=F \
    AUDIT_DATE_START=20260601 AUDIT_DATE_END=20260730 \
    AUDIT_OUT_FILE=$TMPDIR/tc04.csv AUDIT_FORMAT=CSV \
    $DRIVER
N=$((N+1))
if head -1 $TMPDIR/tc04.csv | grep -q "audit_id,bdate"; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d TC04 CSV header present\n" "$N"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d TC04 CSV header missing\n" "$N"
fi

expect_pass "TC05 JSON format" 0 env \
    AUDIT_MODE=F \
    AUDIT_DATE_START=20260601 AUDIT_DATE_END=20260730 \
    AUDIT_MAX_ROWS=10 \
    AUDIT_OUT_FILE=$TMPDIR/tc05.json AUDIT_FORMAT=JSON \
    $DRIVER
N=$((N+1))
if which jq > /dev/null 2>&1; then
    if jq -e '. | length > 0' $TMPDIR/tc05.json > /dev/null 2>&1; then
        PASS=$((PASS+1))
        printf "  [PASS] %03d TC05 JSON valid array\n" "$N"
    else
        FAIL=$((FAIL+1))
        printf "  [FAIL] %03d TC05 JSON invalid\n" "$N"
        head -3 $TMPDIR/tc05.json | sed 's/^/    /'
    fi
else
    if head -1 $TMPDIR/tc05.json | grep -q "^\[" && tail -1 $TMPDIR/tc05.json | grep -q "^\]"; then
        PASS=$((PASS+1))
        printf "  [PASS] %03d TC05 JSON brackets present\n" "$N"
    else
        FAIL=$((FAIL+1))
        printf "  [FAIL] %03d TC05 JSON brackets missing\n" "$N"
    fi
fi

expect_pass "TC06 invalid date range rc=8" 8 env \
    AUDIT_MODE=F \
    AUDIT_DATE_START=20260801 AUDIT_DATE_END=20260601 \
    AUDIT_OUT_FILE=$TMPDIR/tc06.txt AUDIT_FORMAT=TEXT \
    $DRIVER

expect_pass "TC07 invalid format rc=8" 8 env \
    AUDIT_MODE=F \
    AUDIT_DATE_START=20260601 AUDIT_DATE_END=20260730 \
    AUDIT_OUT_FILE=$TMPDIR/tc07.txt AUDIT_FORMAT=XML \
    $DRIVER

expect_pass "TC08 LIMIT=5" 0 env \
    AUDIT_MODE=F \
    AUDIT_DATE_START=20260601 AUDIT_DATE_END=20260730 \
    AUDIT_MAX_ROWS=5 \
    AUDIT_OUT_FILE=$TMPDIR/tc08.txt AUDIT_FORMAT=TEXT \
    $DRIVER
N=$((N+1))
rows=$(grep -cE "^[0-9]+ \|" $TMPDIR/tc08.txt 2>/dev/null | tr -d '[:space:]')
[ -z "$rows" ] && rows=0
if [ "$rows" -le 5 ] && [ "$rows" -ge 1 ]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d TC08 LIMIT enforced (got %d rows)\n" "$N" "$rows"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d TC08 LIMIT exceeded (got %d > 5)\n" "$N" "$rows"
fi

N=$((N+1))
prior_count=$(psql -h $PGHOST -U $PGUSER -d $PGDATABASE -t -A -c \
    "SELECT COUNT(*) FROM audit_log WHERE TRIM(TRAILING FROM action)='AUDIT_QUERY_EXECUTED'")
env AUDIT_MODE=F \
    AUDIT_DATE_START=20260601 AUDIT_DATE_END=20260730 \
    AUDIT_OUT_FILE=$TMPDIR/tc09.txt AUDIT_FORMAT=TEXT \
    $DRIVER > /dev/null 2>&1
new_count=$(psql -h $PGHOST -U $PGUSER -d $PGDATABASE -t -A -c \
    "SELECT COUNT(*) FROM audit_log WHERE TRIM(TRAILING FROM action)='AUDIT_QUERY_EXECUTED'")
if [ "$new_count" -gt "$prior_count" ]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d TC09 AUDIT_QUERY_EXECUTED meta-audit emitted\n" "$N"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d TC09 meta-audit not incremented (%d→%d)\n" "$N" "$prior_count" "$new_count"
fi

expect_pass "TC10 partition rollover dry-run" 0 env \
    AUDIT_MODE=R \
    AUDIT_DRY_RUN=Y \
    $DRIVER

expect_pass "TC11 partition rollover real" 0 env \
    AUDIT_MODE=R \
    AUDIT_DRY_RUN=N \
    $DRIVER

expect_pass "TC12 partition rollover re-run idempotent" 0 env \
    AUDIT_MODE=R \
    AUDIT_DRY_RUN=N \
    $DRIVER

expect_pass "TC13 summary by-day" 0 env \
    AUDIT_MODE=S \
    AUDIT_DATE_START=20260601 AUDIT_DATE_END=20260730 \
    AUDIT_SUMMARY_MODE=D \
    AUDIT_OUT_FILE=$TMPDIR/tc13.txt \
    $DRIVER
N=$((N+1))
if [ -s $TMPDIR/tc13.txt ] && grep -q "Audit Summary Report" $TMPDIR/tc13.txt; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d TC13 summary by-day output\n" "$N"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d TC13 summary missing\n" "$N"
fi

expect_pass "TC-DT1 enumerate-only no DDL" 0 env \
    AUDIT_MODE=R \
    AUDIT_DRY_RUN=N \
    AUDIT_ENABLE_DETACH=N \
    AUDIT_RETENTION_DAYS=30 \
    $DRIVER

N=$((N+1))
prior_part_count=$(psql -h $PGHOST -U $PGUSER -d $PGDATABASE -t -A -c \
    "SELECT COUNT(*) FROM pg_inherits WHERE inhparent='audit_log'::regclass")
psql -h $PGHOST -U $PGUSER -d $PGDATABASE -c \
    "CREATE TABLE IF NOT EXISTS audit_log_201501 PARTITION OF audit_log FOR VALUES FROM ('2015-01-01') TO ('2015-02-01')" > /dev/null 2>&1
post_create_count=$(psql -h $PGHOST -U $PGUSER -d $PGDATABASE -t -A -c \
    "SELECT COUNT(*) FROM pg_inherits WHERE inhparent='audit_log'::regclass")
rc=0
env AUDIT_MODE=R \
    AUDIT_DRY_RUN=N \
    AUDIT_ENABLE_DETACH=Y \
    AUDIT_RETENTION_DAYS=30 \
    $DRIVER > /tmp/audit-test/tc-dt2.log 2>&1 || rc=$?
post_detach_count=$(psql -h $PGHOST -U $PGUSER -d $PGDATABASE -t -A -c \
    "SELECT COUNT(*) FROM pg_inherits WHERE inhparent='audit_log'::regclass")
psql -h $PGHOST -U $PGUSER -d $PGDATABASE -c \
    "DROP TABLE IF EXISTS audit_log_201501" > /dev/null 2>&1
if [ "$rc" = "0" ] && [ "$post_detach_count" -lt "$post_create_count" ]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d TC-DT2 DETACH 1 partition (%d→%d)\n" "$N" "$post_create_count" "$post_detach_count"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d TC-DT2 rc=%d partitions %d→%d (no detach)\n" "$N" "$rc" "$post_create_count" "$post_detach_count"
    cat /tmp/audit-test/tc-dt2.log | head -3 | sed 's/^/    /'
fi

echo "=== Total: $N | PASS: $PASS | FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
