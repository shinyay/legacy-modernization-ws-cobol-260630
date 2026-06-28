#!/usr/bin/env bash
set -u

CON=./bin/oper-console
export PGHOST="${PGHOST:-postgres}" PGUSER="${PGUSER:-cobol}"
export PGPASSWORD="${PGPASSWORD:-cobol}" PGDATABASE="${PGDATABASE:-banking}"
export LD_PRELOAD="${LD_PRELOAD:-/usr/local/lib/libocesql.so}"
export LANG="${LANG:-en_US.UTF-8}" LC_ALL="${LC_ALL:-en_US.UTF-8}"
export CONSOLE_MSG_DIR="${CONSOLE_MSG_DIR:-/workspace/console/msg}"
export CONSOLE_STAGE_SCRIPT="${CONSOLE_STAGE_SCRIPT:-/workspace/console/scripts/run-stage.sh}"
export CONSOLE_ALLOW_DESTRUCTIVE_DEMO_RESET="${CONSOLE_ALLOW_DESTRUCTIVE_DEMO_RESET:-YES}"
PSQL="psql -h $PGHOST -U $PGUSER -d $PGDATABASE -tA"

PASS=0; FAIL=0; declare -a FAILS=()
ok()  { echo "  [PASS] $1"; PASS=$((PASS+1)); }
bad() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); FAILS+=("$1"); }
has() { # label  haystack-file  needle
  if grep -qF "$3" "$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
hasnt() {
  if grep -qF "$3" "$2"; then bad "$1 (unexpected: $3)"; else ok "$1"; fi
}

echo "=== console --no-screen tests ==="
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

$CON --no-screen --lang=ja --tran=BMON > "$TMP/bmon-ja.out" 2>&1
has  "TC1 BMON ja reaches DONE (完了)"      "$TMP/bmon-ja.out" "完了"
hasnt "TC1 BMON ja no failure (失敗)"        "$TMP/bmon-ja.out" "失敗"
has  "TC1 BMON ja posted count txn 90"      "$TMP/bmon-ja.out" "txn 90"

TXN=$($PSQL -c "SELECT count(*) FROM transactions WHERE business_date='2026-06-12'")
DR=$($PSQL -c "SELECT COALESCE(SUM(debit_jpy),0) FROM postings WHERE business_date='2026-06-12'")
CR=$($PSQL -c "SELECT COALESCE(SUM(credit_jpy),0) FROM postings WHERE business_date='2026-06-12'")
[ "$TXN" = "90" ] && ok "TC2 PG transactions=90" || bad "TC2 PG transactions=$TXN (want 90)"
[ "$DR" = "$CR" ] && [ "$DR" != "0" ] && ok "TC2 I2 conservation DR=CR=$DR" \
  || bad "TC2 DR=$DR CR=$CR (want equal, non-zero)"

$CON --no-screen --lang=ja --tran=JRNL > "$TMP/jrnl-ja.out" 2>&1
has "TC3 JRNL ja header (取引仕訳ジャーナル)" "$TMP/jrnl-ja.out" "取引仕訳ジャーナル"
has "TC3 JRNL ja category deposit (入金)"     "$TMP/jrnl-ja.out" "入金"
has "TC3 JRNL ja cash account on debit side"  "$TMP/jrnl-ja.out" "0010010000001"
ROWS=$(grep -cE '^20260612[0-9]{10} ' "$TMP/jrnl-ja.out")
[ "$ROWS" -ge 1 ] 2>/dev/null && ok "TC3 JRNL ja shows >=1 journal row ($ROWS)" \
  || bad "TC3 JRNL ja shows no journal rows"

$CON --no-screen --lang=en --tran=BMON > "$TMP/bmon-en.out" 2>&1
has   "TC4 BMON en label DONE"        "$TMP/bmon-en.out" "DONE"
hasnt "TC4 BMON en has no JP 完了"    "$TMP/bmon-en.out" "完了"
$CON --no-screen --lang=en --tran=JRNL > "$TMP/jrnl-en.out" 2>&1
has   "TC4 JRNL en category Deposit"  "$TMP/jrnl-en.out" "Deposit"

$CON --no-screen --lang=en --tran=ZZZZ > "$TMP/inv.out" 2>&1
has "TC5 invalid tran rejected" "$TMP/inv.out" "Invalid transaction code"

$CON --no-screen --lang=ja --tran=ACCT --key=0010010000001 > "$TMP/acct-ja.out" 2>&1
has "TC6 ACCT ja name (CASH SYSTEM ACCOUNT)" "$TMP/acct-ja.out" "CASH SYSTEM ACCOUNT"
has "TC6 ACCT ja status A"                   "$TMP/acct-ja.out" "状態 A"
has "TC6 ACCT ja customer id"                "$TMP/acct-ja.out" "0000000001"

$CON --no-screen --lang=ja --tran=CUST --key=0000000001 > "$TMP/cust-ja.out" 2>&1
has "TC7 CUST ja name"      "$TMP/cust-ja.out" "PRACTICE BANK SYSTEM CUSTOMER"
has "TC7 CUST ja account 1" "$TMP/cust-ja.out" "0010010000001"
has "TC7 CUST ja account 4" "$TMP/cust-ja.out" "0010010000004"
ACCTS=$(grep -cE '^  001001000000[0-9] ' "$TMP/cust-ja.out")
[ "$ACCTS" -ge 4 ] 2>/dev/null && ok "TC7 CUST ja >=4 accounts ($ACCTS)" \
  || bad "TC7 CUST ja expected >=4 accounts (got $ACCTS)"

$CON --no-screen --lang=ja --tran=HIST --key=0010010000001 > "$TMP/hist-ja.out" 2>&1
has "TC8 HIST ja total 90" "$TMP/hist-ja.out" "total 000090"
ROWS=$(grep -cE '^2026-06-12 [0-9]{18} (DR|CR) ' "$TMP/hist-ja.out")
[ "$ROWS" -ge 1 ] 2>/dev/null && ok "TC8 HIST ja >=1 ledger row ($ROWS)" \
  || bad "TC8 HIST ja no ledger rows"

$CON --no-screen --lang=en --tran=AUDT --key=2026-06-12 > "$TMP/audt-en.out" 2>&1
has "TC9 AUDT en subsystem 12-txnpost"  "$TMP/audt-en.out" "12-txnpost"
has "TC9 AUDT en POST_BATCH_DONE"       "$TMP/audt-en.out" "POST_BATCH_DONE"
has "TC9 AUDT en TXN_POSTED"            "$TMP/audt-en.out" "TXN_POSTED"

$CON --no-screen --lang=en --tran=ACCT --key=9999999999999 > "$TMP/nf.out" 2>&1
has "TC10 ACCT en not found" "$TMP/nf.out" "No matching data"

$CON --no-screen --lang=en --tran=ACCT --key=0010010000001 > "$TMP/acct-en.out" 2>&1
has   "TC11 ACCT en label Account name" "$TMP/acct-en.out" "Account name"
hasnt "TC11 ACCT en has no JP 口座名義"  "$TMP/acct-en.out" "口座名義"

printf 'ACCT\nB\nEXIT\n' | timeout 20 $CON --screen --lang=ja > "$TMP/scr-ja.out" 2>&1
SC_RC=$?
[ "$SC_RC" = "0" ] && ok "TC12 --screen ja clean exit" \
  || bad "TC12 --screen ja exit rc=$SC_RC"
if LC_ALL=C grep -aqP '[\xe3\xe6\xe7\xe5\xe9]' "$TMP/scr-ja.out"; then
  ok "TC12 --screen ja Japanese bytes rendered"
else bad "TC12 --screen ja NO Japanese bytes (regression!)"; fi
if LC_ALL=C grep -aqP '\x1b\[' "$TMP/scr-ja.out"; then
  ok "TC12 --screen ja ANSI escapes present"
else bad "TC12 --screen ja no ANSI escapes"; fi
has   "TC12 --screen ja account title (口座照会)" "$TMP/scr-ja.out" "口座照会"
hasnt "TC12 --screen ja no terminal error" "$TMP/scr-ja.out" "Error opening terminal"

printf 'ACCT\nB\nEXIT\n' | timeout 20 $CON --screen --lang=en > "$TMP/scr-en.out" 2>&1
has   "TC13 --screen en account title"   "$TMP/scr-en.out" "Account Inquiry"
hasnt "TC13 --screen en has no JP 口座照会" "$TMP/scr-en.out" "口座照会"

printf '' | timeout 10 $CON --screen --lang=ja > "$TMP/scr-eof.out" 2>&1
[ "$?" = "0" ] && ok "TC14 --screen EOF clean exit (no hang)" \
  || bad "TC14 --screen EOF did not exit cleanly"

printf 'ACCT\r\nB\r\nEXIT\r\n' | timeout 20 $CON --screen --lang=ja \
  > "$TMP/scr-back.out" 2>&1
BACK_RC=$?
MENU_N=$(grep -aoF 'Tran ===>' "$TMP/scr-back.out" | wc -l)
[ "$BACK_RC" = "0" ] && ok "TC15 --screen B clean exit" \
  || bad "TC15 --screen B exit rc=$BACK_RC"
[ "$MENU_N" -ge 2 ] 2>/dev/null \
  && ok "TC15 --screen B returns to menu (renders x$MENU_N, not quit)" \
  || bad "TC15 --screen B did NOT return to menu (menu rendered x$MENU_N)"

export CONSOLE_OPERATOR_ID="${CONSOLE_OPERATOR_ID:-test-operator}"
revs() { # $1=label-input  runs REVS with write gate ON
  printf "$1" | CONSOLE_ALLOW_WRITE=YES timeout 30 $CON --screen --lang=ja 2>/dev/null
}
rvcount() { # $1=orig-txn -> number of RV rows referencing it
  $PSQL -c "SELECT count(*) FROM transactions WHERE reversal_of='$1' AND status='RV'"
}
$CON --no-screen --lang=ja --tran=BMON >/dev/null 2>&1

revs 'REVS\n202606120000000030\nunit test reversal\nY\n' > "$TMP/revs-ok.out"
has  "TC16 REVS happy shows new RV id" "$TMP/revs-ok.out" "新RV取引ID"
[ "$(rvcount 202606120000000030)" = "1" ] \
  && ok "TC16 REVS happy created RV row in PG" \
  || bad "TC16 REVS happy: no RV row for ...030"

revs 'REVS\n202606120000000030\nsecond attempt\nY\nB\nEXIT\n' > "$TMP/revs-dup.out"
has "TC17 REVS already-reversed -> 08" "$TMP/revs-dup.out" "二重取消"
[ "$(rvcount 202606120000000030)" = "1" ] \
  && ok "TC17 REVS no second RV row created" \
  || bad "TC17 REVS created a duplicate RV row"

revs 'REVS\n202606129999999999\nx\nY\nB\nEXIT\n' > "$TMP/revs-nf.out"
has "TC18 REVS not-found -> message" "$TMP/revs-nf.out" "見つかりません"

revs 'REVS\n12345\nx\nY\nB\nEXIT\n' > "$TMP/revs-bad.out"
has "TC19 REVS bad txn id rejected" "$TMP/revs-bad.out" "18桁"

revs 'REVS\n202606120000000031\nx\nN\nB\nEXIT\n' > "$TMP/revs-no.out"
[ "$(rvcount 202606120000000031)" = "0" ] \
  && ok "TC20 REVS confirm=N made no DB change" \
  || bad "TC20 REVS confirm=N still reversed ...031"

env -u CONSOLE_ALLOW_WRITE bash -c \
  "printf 'REVS\n202606120000000032\nx\nY\nB\nEXIT\n' | timeout 30 $CON --screen --lang=ja 2>/dev/null" \
  > "$TMP/revs-gate.out"
has "TC21 REVS gate-off shows read-only banner" "$TMP/revs-gate.out" "書込無効"
[ "$(rvcount 202606120000000032)" = "0" ] \
  && ok "TC21 REVS gate-off made no DB change" \
  || bad "TC21 REVS gate-off still reversed ...032"

revs 'JRNL\nR1\nN\nB\nEXIT\n' > "$TMP/revs-pick.out"
has "TC22 JRNL R1 jumps to REVS screen" "$TMP/revs-pick.out" "取引取消"

revs 'REVS\n202606120000000033\ntrail check\nY\nB\nEXIT\n' > "$TMP/revs-trail.out"
TRAIL_MENU=$(grep -aoF 'Tran ===>' "$TMP/revs-trail.out" | wc -l)
[ "$TRAIL_MENU" -ge 1 ] 2>/dev/null \
  && ok "TC23 REVS success->JRNL->B returns to menu (x$TRAIL_MENU)" \
  || bad "TC23 REVS post-reversal B did not reach menu (x$TRAIL_MENU)"

printf 'REVS\n202606120000000034\nx\nY\nB\nEXIT\n' \
  | CONSOLE_ALLOW_WRITE=YESX timeout 30 $CON --screen --lang=ja 2>/dev/null \
  > "$TMP/revs-gate3.out"
has   "TC24 REVS script-gate -> gate message"     "$TMP/revs-gate3.out" "書込が無効"
hasnt "TC24 REVS script-gate not shown as I/O err" "$TMP/revs-gate3.out" "入出力エラー"
[ "$(rvcount 202606120000000034)" = "0" ] \
  && ok "TC24 REVS script-gate made no DB change" \
  || bad "TC24 REVS script-gate still reversed ...034"

printf 'JRNL\nB\nEXIT\n' | timeout 20 $CON --screen --lang=ja 2>/dev/null \
  > "$TMP/jrnl-scr.out"
has "TC25 JRNL --screen shows command prompt" "$TMP/jrnl-scr.out" "コマンド ===>"
if LC_ALL=C grep -aqF $'\x1b[22;22H' "$TMP/jrnl-scr.out"; then
  ok "TC25 JRNL input cursor positioned at row 22 (after prompt)"
else bad "TC25 JRNL input cursor escape ESC[22;22H missing"; fi

POST_BD='2026-06-15'
postclean() {
  $PSQL -c "DELETE FROM postings WHERE business_date='$POST_BD'" >/dev/null 2>&1
  $PSQL -c "DELETE FROM transactions WHERE business_date='$POST_BD'" >/dev/null 2>&1
  $PSQL -c "DELETE FROM batch_run WHERE TRIM(batch_id)='OPST20260615'" >/dev/null 2>&1
}
postw() { printf "$1" | CONSOLE_ALLOW_WRITE=YES timeout 40 $CON --screen --lang=ja 2>/dev/null; }
pcount() { $PSQL -c "SELECT count(*) FROM transactions WHERE business_date='$POST_BD'"; }

postclean
postw 'POST\nA\nD\n0010010099001\n5000\nA\nT\n0010010099001\n0010010099002\n2000\nG\nY\nB\nEXIT\n' \
  > "$TMP/post-ok.out"
has "TC26 POST happy shows success" "$TMP/post-ok.out" "記帳完了"
[ "$(pcount)" = "2" ] \
  && ok "TC26 POST happy posted 2 txns on 2026-06-15" \
  || bad "TC26 POST happy: expected 2 txns, got $(pcount)"
DRCR=$($PSQL -c "SELECT COALESCE(SUM(debit_jpy),0)||'/'||COALESCE(SUM(credit_jpy),0) FROM postings WHERE business_date='$POST_BD'")
[ "$DRCR" = "7000/7000" ] \
  && ok "TC26 POST I2 conservation DR=CR=7000" \
  || bad "TC26 POST DR/CR=$DRCR (want 7000/7000)"

postclean
printf 'POST\nA\nD\n0010010099001\n5000\nG\nB\nEXIT\n' \
  | env -u CONSOLE_ALLOW_WRITE timeout 40 $CON --screen --lang=ja 2>/dev/null > "$TMP/post-gate.out"
has "TC27 POST gate-off read-only banner" "$TMP/post-gate.out" "書込無効"
[ "$(pcount)" = "0" ] \
  && ok "TC27 POST gate-off made no DB change" \
  || bad "TC27 POST gate-off still posted"

postclean
postw 'POST\nA\nD\n0010010099001\n5000\nG\nN\nB\nEXIT\n' > "$TMP/post-no.out"
has "TC28 POST confirm=N cancelled" "$TMP/post-no.out" "中止"
[ "$(pcount)" = "0" ] \
  && ok "TC28 POST confirm=N made no DB change" \
  || bad "TC28 POST confirm=N still posted"

postw 'POST\nA\nD\n0010010000001\n5000\nB\nEXIT\n' > "$TMP/post-sys.out"
has "TC29 POST blocks system account" "$TMP/post-sys.out" "システム勘定"

postw 'POST\nA\nT\n0010010099001\n0010010099001\n2000\nB\nEXIT\n' > "$TMP/post-self.out"
has "TC30 POST blocks self-transfer" "$TMP/post-self.out" "同一"

postclean
postw 'POST\nA\nD\n0010010099001\n5000\nG\nY\nB\nEXIT\n' >/dev/null
postw 'POST\nA\nD\n0010010099002\n3000\nG\nY\nB\nEXIT\n' > "$TMP/post-again.out"
has "TC31 POST second-on-same-date refused" "$TMP/post-again.out" "記帳済み"
postclean

postclean
POSTDIR="${CONSOLE_POST_DIR:-/tmp/console-demo/post}"
mkdir -p "$POSTDIR"
{ printf "%-20s\n" "test-operator"; printf "%02d\n" 2
  printf "%-2s%-13s%-13s%015d%-120s\n" "10" "0010010099001" "" 5000 "ok"
  printf "%-2s%-13s%-13s%015d%-120s\n" "10" "9999999999999" "" 3000 "bad"
} > "$POSTDIR/request.txt"
CONSOLE_ALLOW_WRITE=YES bash "$(dirname "$0")/../scripts/run-post.sh" "$POSTDIR" >/dev/null 2>&1
PRES=$(cat "$POSTDIR/result.txt" 2>/dev/null)
case "$PRES" in
  PARTIAL\|1\|*) ok "TC32 run-post.sh reports PARTIAL posted=1 [$PRES]" ;;
  *) bad "TC32 run-post.sh aggregation wrong: [$PRES] (want PARTIAL|1|...)" ;;
esac
postclean

postclean
printf 'POST\nA\nD\n0010010099001\n5000\nG\nY\nB\nBMON\n\nEXIT\n' \
  | CONSOLE_ALLOW_WRITE=YES timeout 60 $CON --screen --lang=ja 2>/dev/null \
  > "$TMP/post-bmon.out"
has "TC33 POST->BMON completes (no reset deadlock)" "$TMP/post-bmon.out" "txn 90"
hasnt "TC33 POST->BMON did not fail" "$TMP/post-bmon.out" "失敗"

postclean
printf 'POST\nA\nD\n0010010099001\n5000\nG\nY\nB\nBMON\n\nPOST\nA\nW\n0010010099001\n3000\nG\nY\nB\nEXIT\n' \
  | CONSOLE_ALLOW_WRITE=YES timeout 90 $CON --screen --lang=ja 2>/dev/null \
  > "$TMP/post-bmon-post.out"
[ "$(pcount)" = "1" ] \
  && ok "TC34 POST after BMON reset posts (batch_run cleared)" \
  || bad "TC34 POST after BMON reset failed (got $(pcount) on $POST_BD)"
postclean

( printf 'BEGIN; SELECT count(*) FROM transactions;\n'; sleep 25 ) \
  | psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" >/dev/null 2>&1 &
ZPID=$!
sleep 1
$CON --no-screen --lang=ja --tran=BMON >/dev/null 2>&1
[ "$($PSQL -c "SELECT count(*) FROM transactions WHERE business_date='2026-06-12'")" = "90" ] \
  && ok "TC35 BMON reset clears a lock-holding idle-in-tx blocker (posts 90)" \
  || bad "TC35 BMON blocked by an idle-in-tx lock holder"
kill $ZPID 2>/dev/null; wait 2>/dev/null

bash /workspace/console/scripts/seed-audit-demo.sh 20260612 >/dev/null 2>&1
printf '' | timeout 20 $CON --screen --lang=en --tran=AUDT --key=2026-06-12 \
  > "$TMP/audt-sev.out" 2>&1 || true
has "TC36 AUDT shows W demo row"        "$TMP/audt-sev.out" "DEMO_RECON_DEFERRED"
has "TC36 AUDT shows E demo row"        "$TMP/audt-sev.out" "DEMO_VALIDATE_REJECTED"
has "TC36 AUDT shows C demo row"        "$TMP/audt-sev.out" "DEMO_BALANCE_BREACH"
has "TC36 AUDT W row coloured yellow"   "$TMP/audt-sev.out" "[1;33m"
has "TC36 AUDT E row coloured red"      "$TMP/audt-sev.out" "[1;31m"
has "TC36 AUDT C row white-on-red"      "$TMP/audt-sev.out" "[1;37;41m"
bash /workspace/console/scripts/seed-audit-demo.sh --clear >/dev/null 2>&1

$CON --no-screen --lang=en --tran=BMON >/dev/null 2>&1
BRST=$($PSQL -c "SELECT status FROM batch_run WHERE batch_id LIKE 'E2E-%' ORDER BY started_ts DESC LIMIT 1")
[ "$BRST" = "OK" ] && ok "TC37 BMON marks its batch_run OK" \
  || bad "TC37 BMON batch_run status=$BRST (want OK)"
$CON --no-screen --lang=en --tran=BRUN > "$TMP/brun.out" 2>&1
has "TC37 BRUN lists the daily batch"  "$TMP/brun.out" "E2E-CONS-01"
has "TC37 BRUN shows OK status"        "$TMP/brun.out" "OK"
bash /workspace/console/scripts/seed-batch-demo.sh >/dev/null 2>&1
printf '' | timeout 20 $CON --screen --lang=en --tran=BRUN \
  > "$TMP/brun-scr.out" 2>&1 || true
has "TC37 BRUN shows DEMO-FL row"      "$TMP/brun-scr.out" "DEMO-FL-DAILY"
has "TC37 BRUN RN row yellow"          "$TMP/brun-scr.out" "[1;33m"
has "TC37 BRUN FL row red"             "$TMP/brun-scr.out" "[1;31m"
has "TC37 BRUN AB row white-on-red"    "$TMP/brun-scr.out" "[1;37;41m"
bash /workspace/console/scripts/seed-batch-demo.sh --clear >/dev/null 2>&1

$CON --no-screen --lang=en --tran=SCEN --scen=recon > "$TMP/scen-recon.out" 2>&1
has "TC38 SCEN ran recon"            "$TMP/scen-recon.out" "Scenario recon"
has "TC38 SCEN recon result PASS"    "$TMP/scen-recon.out" "[ PASS ]"
has "TC38 SCEN recon FAIL=0"         "$TMP/scen-recon.out" "FAIL=0"

env -u CONSOLE_ALLOW_DESTRUCTIVE_DEMO_RESET $CON --no-screen --lang=en \
  --tran=SCEN --scen=recon > "$TMP/scen-gate.out" 2>&1
has "TC39 SCEN gate-off message"     "$TMP/scen-gate.out" "Destructive demo OFF"

mkdir -p "$TMP/scendir"
bash /workspace/console/scripts/run-scenario.sh smoke "$TMP/scendir" >/dev/null 2>&1
SCRES=$(cat "$TMP/scendir/scenario-smoke.result" 2>/dev/null)
if echo "$SCRES" | grep -qE '^SCEN\|smoke\|[0-9]+\|0\|0\|[0-9]+$'; then
  ok "TC40 run-scenario smoke PASS rc0 ($SCRES)"
else
  bad "TC40 run-scenario smoke result unexpected ($SCRES)"
fi

printf 'W\nB\n' | CONSOLE_WATCH_CYCLES=2 CONSOLE_WATCH_MS=0 \
  timeout 20 $CON --screen --lang=en --tran=BRUN > "$TMP/watch.out" 2>&1 || true
has "TC41 BRUN watch shows WATCH indicator" "$TMP/watch.out" "WATCH"
WN=$(grep -aoF "Batch Run Monitor" "$TMP/watch.out" | wc -l)
[ "$WN" -ge 3 ] 2>/dev/null \
  && ok "TC41 BRUN watch re-rendered (x$WN >= 3)" \
  || bad "TC41 BRUN watch did not re-render (x$WN)"

echo "=== console tests: PASS=$PASS FAIL=$FAIL ==="
if [ "$FAIL" -gt 0 ]; then
  echo "FAILED: ${FAILS[*]}" >&2
  exit 1
fi
exit 0
