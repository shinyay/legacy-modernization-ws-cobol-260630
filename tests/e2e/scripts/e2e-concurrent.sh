#!/usr/bin/env bash
set -u

PGHOST="${PGHOST:-postgres}"; PGUSER="${PGUSER:-cobol}"
PGPASSWORD="${PGPASSWORD:-cobol}"; PGDATABASE="${PGDATABASE:-banking}"
export PGHOST PGUSER PGPASSWORD PGDATABASE
export LD_PRELOAD="${LD_PRELOAD:-/usr/local/lib/libocesql.so}"
PSQL="psql -h $PGHOST -U $PGUSER -d $PGDATABASE -tA"

WS=/workspace
E2E_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKDIR=/tmp/e2e-conc
mkdir -p "$WORKDIR"
export COB_LIBRARY_PATH=\
$WS/subsystems/12-txnpost/bin:\
$WS/subsystems/01-calendar/bin:\
$WS/subsystems/02-branch/bin:\
$WS/subsystems/05-product/bin:\
$WS/subsystems/08-account/bin:\
$WS/shared/util/aud-write/bin:\
$WS/shared/util/shared-log/bin

CASH=0010010000001
ACCT1=0010010099001
ACCT2=0010010099002

PASS=0; FAIL=0; declare -a FAILS=()
ok()   { echo "  [PASS] $1"; PASS=$((PASS+1)); }
bad()  { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); FAILS+=("$1"); }
chk()  { # label expected actual
  if [ "$2" = "$3" ]; then ok "$1 = $3"; else bad "$1 expected=$2 actual=$3"; fi
}

BLOCKER_PID=""
cleanup() {
  if [ -n "$BLOCKER_PID" ] && kill -0 "$BLOCKER_PID" 2>/dev/null; then
    kill "$BLOCKER_PID" 2>/dev/null
  fi
  psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -tA -c \
    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity
     WHERE usename='$PGUSER' AND query ILIKE '%pg_sleep(60)%'
       AND pid <> pg_backend_pid()" >/dev/null 2>&1 || true
}
trap cleanup EXIT

seed() {
  bash "$WS/subsystems/22-operations/src/ops-seed-system-accounts.sh" >/dev/null 2>&1
  bash "$E2E_ROOT/scripts/e2e-prep-pg.sh" >/dev/null 2>&1
  "$E2E_ROOT/bin/e2e-seed-isam" >/dev/null 2>&1
}

echo "=== #43 concurrent posting safety test ==="
echo "[stage 0] build + seed"
make -C "$E2E_ROOT" build >/dev/null 2>&1 || { echo "build failed"; exit 1; }

echo "[test 1] FOR UPDATE pessimistic-lock proof (controlled blocker)"
seed
BATCH1=E2E-CONC-T1
BDATE1=20260612
E2E_CONC_PATH="$WORKDIR/t1.dat" E2E_BATCH_ID="$BATCH1" E2E_BDATE="$BDATE1" \
  E2E_CONC_COUNT=3 E2E_CONC_CAT=10 E2E_CONC_PAYER="$ACCT1" E2E_CONC_AMOUNT=1000 \
  "$E2E_ROOT/bin/e2e-conc-gen" >/dev/null

psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" \
  -c "BEGIN; SELECT 1 FROM balances WHERE account_number='$CASH' FOR UPDATE; SELECT pg_sleep(60);" \
  >/dev/null 2>&1 &
BLOCKER_PID=$!
sleep 1.5

mkdir -p "$WORKDIR/t1"
"$E2E_ROOT/bin/e2e-driver" stage5 "$BATCH1" "$BDATE1" "$WORKDIR/t1.dat" \
  "$WORKDIR/t1/e.dat" "$WORKDIR/t1/r.dat" "$WORKDIR/t1/c.dat" "$WORKDIR/t1/d.dat" \
  >"$WORKDIR/t1/out" 2>&1 &
TXPOST1=$!

blocked="0"; blocker_be=""
for _ in $(seq 1 20); do
  blocked=$($PSQL -c "
    SELECT count(*) FROM pg_stat_activity
    WHERE usename='$PGUSER' AND state='active'
      AND wait_event_type='Lock'
      AND cardinality(pg_blocking_pids(pid))>0
      AND query ILIKE '%FOR UPDATE%' AND query ILIKE '%balances%'")
  if [ "${blocked:-0}" -ge 1 ] 2>/dev/null; then
    blocker_be=$($PSQL -c "
      SELECT (pg_blocking_pids(pid))[1] FROM pg_stat_activity
      WHERE usename='$PGUSER' AND state='active'
        AND wait_event_type='Lock' AND cardinality(pg_blocking_pids(pid))>0
        AND query ILIKE '%FOR UPDATE%' AND query ILIKE '%balances%' LIMIT 1")
    break
  fi
  sleep 0.5
done
if [ "${blocked:-0}" -ge 1 ] 2>/dev/null; then
  ok "T1 TXPOST blocked on balances FOR UPDATE (=$blocked)"
else
  bad "T1 TXPOST did not block on balances FOR UPDATE (=$blocked)"
fi

posted_while_blocked=$($PSQL -c "SELECT count(*) FROM transactions WHERE TRIM(source_batch_id)='$BATCH1'")
chk "T1 zero posted while blocked" 0 "$posted_while_blocked"

if [ -n "$blocker_be" ]; then
  $PSQL -c "SELECT pg_terminate_backend($blocker_be)" >/dev/null 2>&1
fi
kill "$BLOCKER_PID" 2>/dev/null; wait "$BLOCKER_PID" 2>/dev/null; BLOCKER_PID=""
wait "$TXPOST1"; RC1=$?
chk "T1 TXPOST rc=0 after release" 0 "$RC1"
t1_posted=$($PSQL -c "SELECT count(*) FROM transactions WHERE TRIM(source_batch_id)='$BATCH1'")
chk "T1 deposits posted after release" 3 "$t1_posted"

echo "[test 2] C1 deadlock-freedom + concurrent integrity (opposite-direction transfers)"
seed
M=200
$PSQL -c "UPDATE balances SET balance_jpy=100000000, available_jpy=100000000 WHERE account_number IN ('$ACCT1','$ACCT2')" >/dev/null
INIT1=$($PSQL -c "SELECT balance_jpy FROM balances WHERE account_number='$ACCT1'")
INIT2=$($PSQL -c "SELECT balance_jpy FROM balances WHERE account_number='$ACCT2'")

BATCHA=E2E-CONC-A01; BDATEA=20260612
BATCHB=E2E-CONC-B01; BDATEB=20260613
E2E_CONC_PATH="$WORKDIR/A.dat" E2E_BATCH_ID="$BATCHA" E2E_BDATE="$BDATEA" \
  E2E_CONC_COUNT=$M E2E_CONC_CAT=30 E2E_CONC_PAYER="$ACCT1" E2E_CONC_PAYEE="$ACCT2" \
  E2E_CONC_AMOUNT=1000 "$E2E_ROOT/bin/e2e-conc-gen" >/dev/null
E2E_CONC_PATH="$WORKDIR/B.dat" E2E_BATCH_ID="$BATCHB" E2E_BDATE="$BDATEB" \
  E2E_CONC_COUNT=$M E2E_CONC_CAT=30 E2E_CONC_PAYER="$ACCT2" E2E_CONC_PAYEE="$ACCT1" \
  E2E_CONC_AMOUNT=1000 "$E2E_ROOT/bin/e2e-conc-gen" >/dev/null

mkdir -p "$WORKDIR/cA" "$WORKDIR/cB"
export TXPOST_MAX_RETRIES=50 TXPOST_BACKOFF_MS=5
"$E2E_ROOT/bin/e2e-driver" stage5 "$BATCHA" "$BDATEA" "$WORKDIR/A.dat" \
  "$WORKDIR/cA/e.dat" "$WORKDIR/cA/r.dat" "$WORKDIR/cA/c.dat" "$WORKDIR/cA/d.dat" \
  >"$WORKDIR/cA/out" 2>&1 &
PA=$!
"$E2E_ROOT/bin/e2e-driver" stage5 "$BATCHB" "$BDATEB" "$WORKDIR/B.dat" \
  "$WORKDIR/cB/e.dat" "$WORKDIR/cB/r.dat" "$WORKDIR/cB/c.dat" "$WORKDIR/cB/d.dat" \
  >"$WORKDIR/cB/out" 2>&1 &
PB=$!

contention=0
for _ in $(seq 1 30); do
  c=$($PSQL -c "
    SELECT count(*) FROM pg_stat_activity
    WHERE usename='$PGUSER' AND state='active'
      AND wait_event_type='Lock' AND cardinality(pg_blocking_pids(pid))>0")
  [ "${c:-0}" -ge 1 ] 2>/dev/null && { contention=1; break; }
  kill -0 "$PA" 2>/dev/null || kill -0 "$PB" 2>/dev/null || break
  sleep 0.2
done
wait "$PA"; RA=$?
wait "$PB"; RB=$?

if [ "$contention" -ge 1 ]; then
  ok "T2 real lock contention observed"
else
  echo "  [WARN] T2 contention not sampled (deterministic assertions are authoritative)"
fi
chk "T2 batch A rc=0" 0 "$RA"
chk "T2 batch B rc=0" 0 "$RB"

if grep -qil "40P01\|deadlock" "$WORKDIR/cA/out" "$WORKDIR/cB/out" 2>/dev/null; then
  bad "T2 deadlock detected (C1 ordering failed)"
else
  ok "T2 no deadlock (C1 canonical ordering held)"
fi

statA=$(grep -oE '"status":"[0-9]+"' "$WORKDIR/cA/out" | grep -oE '[0-9]+' | head -1)
statB=$(grep -oE '"status":"[0-9]+"' "$WORKDIR/cB/out" | grep -oE '[0-9]+' | head -1)
postedA=$(grep -oE '"records_posted":[0-9]+' "$WORKDIR/cA/out" | grep -oE '[0-9]+$' | head -1)
postedB=$(grep -oE '"records_posted":[0-9]+' "$WORKDIR/cB/out" | grep -oE '[0-9]+$' | head -1)
rejA=$(grep -oE '"hard_rejected":[0-9]+' "$WORKDIR/cA/out" | grep -oE '[0-9]+$' | head -1)
rejB=$(grep -oE '"hard_rejected":[0-9]+' "$WORKDIR/cB/out" | grep -oE '[0-9]+$' | head -1)
chk "T2 batch A status 00" 0 "$((10#${statA:-99}))"
chk "T2 batch B status 00" 0 "$((10#${statB:-99}))"
chk "T2 batch A posted M" "$M" "$((10#${postedA:-0}))"
chk "T2 batch B posted M" "$M" "$((10#${postedB:-0}))"
chk "T2 batch A hard_rejected 0" 0 "$((10#${rejA:-9}))"
chk "T2 batch B hard_rejected 0" 0 "$((10#${rejB:-9}))"

retA=$(grep -aoE 'retries=[0-9]+' "$WORKDIR/cA/out" | grep -oE '[0-9]+$' | head -1)
retB=$(grep -aoE 'retries=[0-9]+' "$WORKDIR/cB/out" | grep -oE '[0-9]+$' | head -1)
exhA=$(grep -aoE 'exhausted=[0-9]+' "$WORKDIR/cA/out" | grep -oE '[0-9]+$' | head -1)
exhB=$(grep -aoE 'exhausted=[0-9]+' "$WORKDIR/cB/out" | grep -oE '[0-9]+$' | head -1)
echo "  [info] T2 ser_metrics A retries=$((10#${retA:-0})) exhausted=$((10#${exhA:-0}))" \
     "B retries=$((10#${retB:-0})) exhausted=$((10#${exhB:-0}))"
chk "T2 batch A no exhaustion" 0 "$((10#${exhA:-9}))"
chk "T2 batch B no exhaustion" 0 "$((10#${exhB:-9}))"

txns=$($PSQL -c "SELECT count(*) FROM transactions WHERE TRIM(source_batch_id) IN ('$BATCHA','$BATCHB')")
posts=$($PSQL -c "SELECT count(*) FROM postings WHERE business_date IN ('2026-06-12','2026-06-13')")
chk "T2 transactions = 2M" "$((2*M))" "$txns"
chk "T2 postings = 4M" "$((4*M))" "$posts"

fin1=$($PSQL -c "SELECT balance_jpy FROM balances WHERE account_number='$ACCT1'")
fin2=$($PSQL -c "SELECT balance_jpy FROM balances WHERE account_number='$ACCT2'")
chk "T2 acct1 net-zero final balance" "$INIT1" "$fin1"
chk "T2 acct2 net-zero final balance" "$INIT2" "$fin2"

dr=$($PSQL -c "SELECT COALESCE(SUM(debit_jpy),0) FROM postings WHERE business_date IN ('2026-06-12','2026-06-13')")
cr=$($PSQL -c "SELECT COALESCE(SUM(credit_jpy),0) FROM postings WHERE business_date IN ('2026-06-12','2026-06-13')")
chk "T2 I2 conservation DR=CR" "$dr" "$cr"

echo "=== concurrent test: PASS=$PASS FAIL=$FAIL ==="
if [ "$FAIL" -gt 0 ]; then
  echo "FAILED: ${FAILS[*]}" >&2
  exit 1
fi
exit 0
