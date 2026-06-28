#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
export PGHOST="${PGHOST:-postgres}"
export PGUSER="${PGUSER:-cobol}"
export PGDATABASE="${PGDATABASE:-banking}"
export LD_LIBRARY_PATH="/workspace/shared/util/mq-publish/bin:$LD_LIBRARY_PATH"

DRIVER="/workspace/subsystems/20-integrationout/bin/into-driver"
MOCK_OUT="/tmp/mq-mock-out.dat"

PASS=0
FAIL=0
N=0

rm -f $MOCK_OUT

echo "=== 20-integrationout unit tests (Phase 7 Step 2) ==="

N=$((N+1))
rm -f $MOCK_OUT
INTO_EVENT_TYPE="txn.posted" \
INTO_BUSINESS_DATE="20260613" \
INTO_BATCH_ID="EOD20260613-01" \
INTO_TXN_ID="202606130000000001" \
INTO_ACCOUNT="0010010099701" \
INTO_AMOUNT_JPY="10000" \
INTO_CATEGORY="10" \
INTO_MODE="M" \
$DRIVER > /tmp/into-out1.log 2>&1
rc=$?
if [ "$rc" = "0" ] && grep -q '"eventType":"txn.posted"' $MOCK_OUT 2>/dev/null; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d txn.posted mock publish\n" "$N"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d rc=%d output:\n" "$N" "$rc"
    cat /tmp/into-out1.log | head -3 | sed 's/^/    /'
    head -1 $MOCK_OUT 2>/dev/null | sed 's/^/    out: /'
fi

N=$((N+1))
if which jq > /dev/null 2>&1; then
    if jq -e '.version, .eventId, .eventType, .businessDate, .publishedAt, .source, .payload' $MOCK_OUT > /dev/null 2>&1; then
        PASS=$((PASS+1))
        printf "  [PASS] %03d envelope has all 7 fields (jq)\n" "$N"
    else
        FAIL=$((FAIL+1))
        printf "  [FAIL] %03d envelope missing fields\n" "$N"
        cat $MOCK_OUT | sed 's/^/    /'
    fi
else
    if grep -q '"version":"1.0"' $MOCK_OUT && \
       grep -q '"eventType":"txn.posted"' $MOCK_OUT && \
       grep -q '"businessDate":' $MOCK_OUT && \
       grep -q '"publishedAt":' $MOCK_OUT && \
       grep -q '"source":"pb-core-batch"' $MOCK_OUT && \
       grep -q '"payload":' $MOCK_OUT; then
        PASS=$((PASS+1))
        printf "  [PASS] %03d envelope has all 7 fields (grep)\n" "$N"
    else
        FAIL=$((FAIL+1))
        printf "  [FAIL] %03d envelope missing fields\n" "$N"
    fi
fi

N=$((N+1))
event_id=$(grep -oE '"eventId":"[a-f0-9-]+"' $MOCK_OUT | head -1 | sed 's/"eventId":"\(.*\)"/\1/')
if [[ "$event_id" =~ ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ ]]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d UUID v4 format (%s)\n" "$N" "$event_id"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d UUID invalid: %s\n" "$N" "$event_id"
fi

N=$((N+1))
ts=$(grep -oE '"publishedAt":"[^"]+"' $MOCK_OUT | head -1 | sed 's/"publishedAt":"\(.*\)"/\1/')
if [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d timestamp ISO-8601 UTC (%s)\n" "$N" "$ts"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d timestamp invalid: %s\n" "$N" "$ts"
fi

test_event_type() {
    local event_name="$1"
    local check_payload_field="$2"
    N=$((N+1))
    rm -f $MOCK_OUT
    INTO_EVENT_TYPE="$event_name" \
    INTO_BUSINESS_DATE="20260613" \
    INTO_BATCH_ID="EOD20260613-01" \
    INTO_TXN_ID="202606130000000099" \
    INTO_ACCOUNT="0010010099702" \
    INTO_AMOUNT_JPY="5000" \
    INTO_CATEGORY="20" \
    INTO_REASON="NF" \
    INTO_COUNT="42" \
    INTO_MODE="M" \
    $DRIVER > /dev/null 2>&1 || true
    if grep -q "\"eventType\":\"$event_name\"" $MOCK_OUT 2>/dev/null && \
       grep -q "\"$check_payload_field\"" $MOCK_OUT 2>/dev/null; then
        PASS=$((PASS+1))
        printf "  [PASS] %03d event=%s has field %s\n" "$N" "$event_name" "$check_payload_field"
    else
        FAIL=$((FAIL+1))
        printf "  [FAIL] %03d event=%s missing %s\n" "$N" "$event_name" "$check_payload_field"
    fi
}

test_event_type "txn.posted" "txnId"
test_event_type "interest.posted" "interestJpy"
test_event_type "autodebit.failed" "reason"
test_event_type "batch.completed" "recordCount"
test_event_type "statement.generated" "accountCount"

N=$((N+1))
rc=0
INTO_EVENT_TYPE="invalid.type" \
INTO_BUSINESS_DATE="20260613" \
INTO_MODE="M" \
$DRIVER > /dev/null 2>&1 || rc=$?
if [ "$rc" = "8" ]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d invalid event_type rc=8\n" "$N"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d invalid event_type rc=%d (expected 8)\n" "$N" "$rc"
fi

N=$((N+1))
prior_count=$(psql -h $PGHOST -U $PGUSER -d $PGDATABASE -t -A -c \
    "SELECT COUNT(*) FROM audit_log WHERE TRIM(TRAILING FROM subsystem)='20-integrationout' AND business_date='2026-06-13'")
INTO_EVENT_TYPE="txn.posted" \
INTO_BUSINESS_DATE="20260613" \
INTO_TXN_ID="202606130000000099" \
INTO_ACCOUNT="0010010099703" \
INTO_AMOUNT_JPY="10000" \
INTO_CATEGORY="10" \
INTO_MODE="M" \
$DRIVER > /dev/null 2>&1 || true
new_count=$(psql -h $PGHOST -U $PGUSER -d $PGDATABASE -t -A -c \
    "SELECT COUNT(*) FROM audit_log WHERE TRIM(TRAILING FROM subsystem)='20-integrationout' AND business_date='2026-06-13'")
if [ "$new_count" -gt "$prior_count" ]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d audit rows emitted (%d -> %d)\n" "$N" "$prior_count" "$new_count"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d audit count not incremented (%d -> %d)\n" "$N" "$prior_count" "$new_count"
fi

if [ "${INTO_TEST_REAL_BROKER:-}" = "Y" ]; then
    N=$((N+1))
    curl -s -u cobol:cobol -X PUT -H "content-type: application/json" \
         -d '{"durable":true}' \
         "http://rabbitmq:15672/api/queues/%2F/pb.events" > /dev/null 2>&1 || true
    rc=0
    INTO_EVENT_TYPE="txn.posted" \
    INTO_BUSINESS_DATE="20260613" \
    INTO_TXN_ID="202606130000000088" \
    INTO_ACCOUNT="0010010099704" \
    INTO_AMOUNT_JPY="999" \
    INTO_CATEGORY="10" \
    INTO_MODE="R" \
    $DRIVER > /tmp/into-real.log 2>&1 || rc=$?
    if [ "$rc" = "0" ]; then
        PASS=$((PASS+1))
        printf "  [PASS] %03d real broker publish OK\n" "$N"
    else
        FAIL=$((FAIL+1))
        printf "  [FAIL] %03d real broker rc=%d\n" "$N" "$rc"
        cat /tmp/into-real.log | head -3 | sed 's/^/    /'
    fi
fi

N=$((N+1))
rm -f /tmp/nonexistent-failed.dat
rc=0
INTO_OP=D \
INTD_SOURCE_FILE=/tmp/nonexistent-failed.dat \
INTD_MODE=M \
$DRIVER > /tmp/into-d1.log 2>&1 || rc=$?
if [ "$rc" = "0" ]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d TC-D1 drain empty file rc=0\n" "$N"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d TC-D1 rc=%d (expected 0)\n" "$N" "$rc"
    cat /tmp/into-d1.log | head -3 | sed 's/^/    /'
fi

N=$((N+1))
rm -f /tmp/test-failed.dat $MOCK_OUT
for i in 1 2 3 4 5; do
    printf "AD-TEST-%03d         %08d%-13s%-80s%015d%-2s%-20s%02d%08d%014d%-18s" \
        $i 20260613 "0010010099201" "Test Payee $i" 1000 "NF" "insufficient funds" 0 20260620 20260613120000 "" >> /tmp/test-failed.dat
done
rc=0
INTO_OP=D \
INTD_SOURCE_FILE=/tmp/test-failed.dat \
INTD_MODE=M \
$DRIVER > /tmp/into-d2.log 2>&1 || rc=$?
drained=$(grep "DRAINED=" /tmp/into-d2.log | sed 's/.*DRAINED=0*\([0-9]*\) .*/\1/')
[ -z "$drained" ] && drained=0
if [ "$rc" = "0" ] && [ "$drained" -ge 1 ]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d TC-D2 5-record drain (drained=%d)\n" "$N" "$drained"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d TC-D2 rc=%d drained=%d\n" "$N" "$rc" "$drained"
    cat /tmp/into-d2.log | head -3 | sed 's/^/    /'
fi

N=$((N+1))
count_evt=$(grep -c '"eventType":"autodebit.failed"' $MOCK_OUT 2>/dev/null || echo 0)
count_evt=$(echo "$count_evt" | tr -d '[:space:]')
if [ -n "$count_evt" ] && [ "$count_evt" -ge 1 ]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d TC-D3 mock has autodebit.failed events (=%d)\n" "$N" "$count_evt"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d TC-D3 no autodebit.failed in mock\n" "$N"
fi

echo "=== Total: $N | PASS: $PASS | FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
