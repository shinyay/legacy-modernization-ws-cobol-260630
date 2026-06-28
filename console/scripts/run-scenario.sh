#!/usr/bin/env bash
set -u

VERB="${1:?verb required}"
WORKDIR="${2:?workdir required}"

if [ "${CONSOLE_ALLOW_DESTRUCTIVE_DEMO_RESET:-NO}" != "YES" ]; then
  echo "refused: set CONSOLE_ALLOW_DESTRUCTIVE_DEMO_RESET=YES" >&2
  exit 3
fi

WS=/workspace
E2E=$WS/tests/e2e
export PGHOST="${PGHOST:-postgres}" PGUSER="${PGUSER:-cobol}"
export PGPASSWORD="${PGPASSWORD:-cobol}" PGDATABASE="${PGDATABASE:-banking}"

mkdir -p "$WORKDIR"
LOG="$WORKDIR/scenario-${VERB}.log"
RESULT="$WORKDIR/scenario-${VERB}.result"
KEYS="$WORKDIR/scenario-${VERB}.keys"

case "$VERB" in
  recon)      SCRIPT=(bash "$E2E/scripts/e2e-run.sh" recon) ;;
  smoke)      SCRIPT=(bash "$E2E/scripts/e2e-run.sh" smoke) ;;
  concurrent) SCRIPT=(bash "$E2E/scripts/e2e-concurrent.sh") ;;
  *) echo "unknown scenario verb: $VERB" >&2; exit 2 ;;
esac

START=$(date +%s)
"${SCRIPT[@]}" < /dev/null > "$LOG" 2>&1
rc=$?
END=$(date +%s)
ELAPSED=$((END - START))

SUMMARY=$(grep -aoE 'PASS=[0-9]+ FAIL=[0-9]+' "$LOG" | tail -1)
PASS=$(printf '%s' "$SUMMARY" | grep -oE 'PASS=[0-9]+' | grep -oE '[0-9]+')
FAIL=$(printf '%s' "$SUMMARY" | grep -oE 'FAIL=[0-9]+' | grep -oE '[0-9]+')
[ -z "$PASS" ] && PASS=0
[ -z "$FAIL" ] && FAIL=0

printf 'SCEN|%s|%s|%s|%s|%s\n' "$VERB" "$PASS" "$FAIL" "$rc" "$ELAPSED" > "$RESULT"

{
  grep -aE '\[(FAIL|WARN)\]' "$LOG" 2>/dev/null
  grep -aE '\[PASS\]' "$LOG" 2>/dev/null | head -6
} | head -7 | sed -E 's/^[[:space:]]+//; s/(.{72}).*/\1/' > "$KEYS"

exit $rc
