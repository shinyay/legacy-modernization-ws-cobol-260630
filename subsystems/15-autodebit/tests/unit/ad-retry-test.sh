#!/usr/bin/env bash
set -u

WS=/workspace
cd "$WS/subsystems/15-autodebit"
export COB_LIBRARY_PATH="bin:$WS/subsystems/01-calendar/bin:\
$WS/subsystems/08-account/bin:$WS/shared/util/aud-write/bin:\
$WS/shared/util/shared-log/bin"
export LD_PRELOAD=/usr/local/lib/libocesql.so
export PGHOST=postgres PGUSER=cobol PGPASSWORD=cobol PGDATABASE=banking

PASS=0; FAIL=0; declare -a FAILS=()
chk(){ if [ "$2" = "$3" ]; then echo "  [PASS] $1 = $3"; PASS=$((PASS+1));
  else echo "  [FAIL] $1 exp=$2 act=$3"; FAIL=$((FAIL+1)); FAILS+=("$1"); fi; }
gt0(){ if [ "$((10#${2:-0}))" -gt 0 ]; then echo "  [PASS] $1 = $2"; PASS=$((PASS+1));
  else echo "  [FAIL] $1 (not > 0)"; FAIL=$((FAIL+1)); FAILS+=("$1"); fi; }
maxret(){ echo "$1" | grep -aoE 'retries=[0-9]+' | grep -oE '[0-9]+$' | sort -rn | head -1; }

echo "=== C-1c 15-autodebit SERIALIZABLE retry FSM test ==="

echo "[A] retry-and-succeed: SER_FAULT_CONFLICT_N=2 SER_MAX_RETRIES=5"
A=$(SER_FAULT_CONFLICT_N=2 SER_MAX_RETRIES=5 SER_BACKOFF_MS=0 ./bin/ad-test 2>&1)
retA=$(maxret "$A")
tc01A=$(echo "$A" | grep -aE '\] 001 ' | tail -1)
echo "  [info] A TC01=[$tc01A] max_retries=$retA"
if echo "$tc01A" | grep -qaE '\[PASS\]'; then
  echo "  [PASS] A debit posts under retry"; PASS=$((PASS+1))
else
  echo "  [FAIL] A debit did not post under retry"; FAIL=$((FAIL+1)); FAILS+=("A post"); fi
gt0 "A retries observed"            "${retA:-0}"

echo "[B] exhaustion: SER_FAULT_CONFLICT_N=10 SER_MAX_RETRIES=2"
B=$(SER_FAULT_CONFLICT_N=10 SER_MAX_RETRIES=2 SER_BACKOFF_MS=0 ./bin/ad-test 2>&1)
postedB=$(echo "$B" | grep -aE '\] 001 ' | grep -aoE 'posted=[0-9]+' | grep -oE '[0-9]+$' | head -1)
retB=$(maxret "$B")
echo "  [info] B TC01 posted=${postedB:-?} max_retries=$retB"
chk "B exhaustion => happy debit posts 0" 0 "$((10#${postedB:-9}))"
gt0 "B retries observed"            "${retB:-0}"

echo "[verify] PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -gt 0 ]; then echo "FAILED: ${FAILS[*]}"; exit 1; fi
echo "=== C-1c 15-autodebit retry test COMPLETE ==="
