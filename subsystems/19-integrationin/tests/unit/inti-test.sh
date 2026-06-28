#!/usr/bin/env bash
set -e
export PGPASSWORD="${PGPASSWORD:-cobol}"
export PGHOST="${PGHOST:-postgres}"
export PGUSER="${PGUSER:-cobol}"
export PGDATABASE="${PGDATABASE:-banking}"
export LD_LIBRARY_PATH="/workspace/shared/util/ebc-to-ascii/bin:$LD_LIBRARY_PATH"

DRIVER="/workspace/subsystems/19-integrationin/bin/inti-driver"
TMPDIR="/tmp/inti-test"
mkdir -p $TMPDIR

PASS=0
FAIL=0
N=0

echo "=== 19-integrationin unit tests (Phase 7 Step 1) ==="

make_detail() {
    local bank="$1" branch="$2" cat="$3" amount="$4" payer="$5" payee="$6" \
          desc="$7" seq="$8" prod="$9" yy="${10}" mm="${11}" dd="${12}"
    printf "D%04d%03d%02d%015d%-13s%-13s%-120s%010d%03d%03d%02d%02d%02d" \
        "$bank" "$branch" "$cat" "$amount" "$payer" "$payee" "$desc" "$seq" \
        "$branch" "$prod" "$yy" "$mm" "$dd" | \
    awk '{ printf "%-800s", $0 }'
}

make_header() {
    local batch="$1" bdate="$2" expected="$3"
    printf "H%-14s%08d%-20s%010d%-40s" \
        "$batch" "$bdate" "EBCDIC_BATCH" "$expected" "0000000000" | \
    awk '{ printf "%-800s", $0 }'
}

make_trailer() {
    local count="$1"
    printf "T%010d%020d%-40s" "$count" 0 "0000000000" | \
    awk '{ printf "%-800s", $0 }'
}

build_happy_fixture() {
    local f="$TMPDIR/happy.ebc"
    {
        make_header "EBC20260613-01" 20260613 5
        make_detail 1234 001 10 100000 0010010099601 0010010099602 \
                    "Deposit T1" 1001 001 26 06 13
        make_detail 1234 001 20  50000 0010010099601 "             " \
                    "Withdraw T1" 1002 001 26 06 13
        make_detail 1234 001 30  20000 0010010099601 0010010099603 \
                    "Transfer T1" 1003 001 26 06 13
        make_detail 1234 001 40  80000 0010010099601 0010010099604 \
                    "Wire T1" 1004 001 26 06 13
        make_detail 1234 001 10  30000 0010010099602 "             " \
                    "Deposit T2" 1005 001 26 06 13
        make_trailer 5
    } > "$f"
}

build_bad_cat_fixture() {
    local f="$TMPDIR/bad-cat.ebc"
    {
        make_header "EBC20260613-02" 20260613 1
        make_detail 1234 001 99 100000 0010010099601 "             " \
                    "Bad cat" 1001 001 26 06 13
        make_trailer 0
    } > "$f"
}

build_zero_amount_fixture() {
    local f="$TMPDIR/zero-amount.ebc"
    {
        make_header "EBC20260613-03" 20260613 1
        make_detail 1234 001 10 0 0010010099601 "             " \
                    "Zero amount" 1001 001 26 06 13
        make_trailer 0
    } > "$f"
}

build_count_mismatch_fixture() {
    local f="$TMPDIR/count-mismatch.ebc"
    {
        make_header "EBC20260613-04" 20260613 5
        make_detail 1234 001 10 100000 0010010099601 "             " \
                    "Deposit T1" 1001 001 26 06 13
        make_trailer 99
    } > "$f"
}

build_no_header_fixture() {
    local f="$TMPDIR/no-header.ebc"
    {
        make_detail 1234 001 10 100000 0010010099601 "             " \
                    "Deposit T1" 1001 001 26 06 13
        make_trailer 1
    } > "$f"
}

build_over_threshold_fixture() {
    local f="$TMPDIR/over-threshold.ebc"
    {
        make_header "EBC20260613-06" 20260613 4
        make_detail 1234 001 10 100000 0010010099601 "             " \
                    "OK 1" 1001 001 26 06 13
        make_detail 1234 001 99 50000 0010010099601 "             " \
                    "BAD 2" 1002 001 26 06 13
        make_detail 1234 001 99 50000 0010010099601 "             " \
                    "BAD 3" 1003 001 26 06 13
        make_detail 1234 001 99 50000 0010010099601 "             " \
                    "BAD 4" 1004 001 26 06 13
        make_trailer 1
    } > "$f"
}

run_tc() {
    local name="$1" expect_rc="$2"
    shift 2
    N=$((N+1))
    local actual_rc=0
    "$@" > $TMPDIR/inti-output.log 2>&1 || actual_rc=$?
    if [ "$actual_rc" = "$expect_rc" ]; then
        PASS=$((PASS+1))
        printf "  [PASS] %03d %s\n" "$N" "$name"
    else
        FAIL=$((FAIL+1))
        printf "  [FAIL] %03d %s (rc=%d expected %d)\n" "$N" "$name" "$actual_rc" "$expect_rc"
        head -3 $TMPDIR/inti-output.log | sed 's/^/    /'
    fi
}

build_happy_fixture
build_bad_cat_fixture
build_zero_amount_fixture
build_count_mismatch_fixture
build_no_header_fixture
build_over_threshold_fixture

run_driver() {
    local fixture="$1"
    local output="$2"
    local reject="$3"
    INTI_BATCH_ID="EBC20260613-01" \
    INTI_BUSINESS_DATE="20260613" \
    INTI_INPUT_FILE="$TMPDIR/$fixture" \
    INTI_OUTPUT_FILE="$TMPDIR/$output" \
    INTI_REJECT_FILE="$TMPDIR/$reject" \
    INTI_SENTINEL_FILE="" \
    INTI_REQUIRE_SENTINEL="N" \
    INTI_REJECT_THRESHOLD_PCT="20" \
    $DRIVER
}

run_tc "happy 5 details rc=0" 0 run_driver happy.ebc decoded.dat reject.dat

N=$((N+1))
nrecords=$(wc -c < $TMPDIR/decoded.dat 2>/dev/null)
expected=$((7 * 600))
if [ "$nrecords" = "$expected" ]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d output has 7 records (= %d bytes)\n" "$N" "$nrecords"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d output bytes=%d (expected %d)\n" "$N" "$nrecords" "$expected"
fi

run_tc "bad cat 100%% reject rc=4" 4 run_driver bad-cat.ebc decoded2.dat reject2.dat

run_tc "zero amount rc=4" 4 run_driver zero-amount.ebc decoded3.dat reject3.dat

run_tc "count mismatch rc=4" 4 run_driver count-mismatch.ebc decoded4.dat reject4.dat

run_tc "no header rc=4" 4 run_driver no-header.ebc decoded5.dat reject5.dat

run_tc "over threshold rc=4" 4 run_driver over-threshold.ebc decoded6.dat reject6.dat

N=$((N+1))
if [ ! -f $TMPDIR/decoded6.dat ]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d output deleted on threshold breach\n" "$N"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d output still exists after threshold breach\n" "$N"
fi

N=$((N+1))
sentinel_rc=0
INTI_BATCH_ID="EBC20260613-07" \
INTI_BUSINESS_DATE="20260613" \
INTI_INPUT_FILE="$TMPDIR/happy.ebc" \
INTI_OUTPUT_FILE="$TMPDIR/decoded7.dat" \
INTI_REJECT_FILE="$TMPDIR/reject7.dat" \
INTI_SENTINEL_FILE="$TMPDIR/nonexistent.ok" \
INTI_REQUIRE_SENTINEL="Y" \
INTI_REJECT_THRESHOLD_PCT="20" \
$DRIVER > /dev/null 2>&1 || sentinel_rc=$?
if [ "$sentinel_rc" = "1" ]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d sentinel absent rc=1\n" "$N"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d sentinel test rc=%d (expected 1)\n" "$N" "$sentinel_rc"
fi

N=$((N+1))
prior_count=$(psql -h $PGHOST -U $PGUSER -d $PGDATABASE -t -A -c \
    "SELECT COUNT(*) FROM audit_log WHERE TRIM(TRAILING FROM subsystem)='19-integrationin' AND business_date='2026-06-13'")
run_driver happy.ebc decoded-audit.dat reject-audit.dat > /dev/null 2>&1 || true
new_count=$(psql -h $PGHOST -U $PGUSER -d $PGDATABASE -t -A -c \
    "SELECT COUNT(*) FROM audit_log WHERE TRIM(TRAILING FROM subsystem)='19-integrationin' AND business_date='2026-06-13'")
if [ "$new_count" -gt "$prior_count" ]; then
    PASS=$((PASS+1))
    printf "  [PASS] %03d audit rows emitted (%d -> %d)\n" "$N" "$prior_count" "$new_count"
else
    FAIL=$((FAIL+1))
    printf "  [FAIL] %03d audit count not incremented (%d -> %d)\n" "$N" "$prior_count" "$new_count"
fi

echo "=== Total: $N | PASS: $PASS | FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
