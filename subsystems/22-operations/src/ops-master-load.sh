#!/usr/bin/env bash
set -uo pipefail
MASTER="${1:-}"
DRY_RUN="${2:-}"

LOCK_DIR=/tmp/pb-locks
LOCK_FILE="$LOCK_DIR/batch-running.lock"
mkdir -p "$LOCK_DIR"

case "$MASTER" in
    calendar)      LOADER=/workspace/subsystems/01-calendar/bin/cal-load ;     SUBSYS_DIR=/workspace/subsystems/01-calendar ;      LOAD_TARGET=load-idx ;;
    branches)      LOADER=/workspace/subsystems/02-branch/bin/br-load ;        SUBSYS_DIR=/workspace/subsystems/02-branch ;        LOAD_TARGET=load-idx ;;
    customers)     LOADER=/workspace/subsystems/03-customer/bin/cust-load ;    SUBSYS_DIR=/workspace/subsystems/03-customer ;      LOAD_TARGET=load-idx ;;
    products)      LOADER=/workspace/subsystems/05-product/bin/prod-load ;     SUBSYS_DIR=/workspace/subsystems/05-product ;       LOAD_TARGET=load-idx ;;
    interestrates) LOADER=/workspace/subsystems/06-interestrate/bin/irate-load ; SUBSYS_DIR=/workspace/subsystems/06-interestrate ; LOAD_TARGET=load-idx ;;
    feeschedules)  LOADER=/workspace/subsystems/07-feeschedule/bin/fee-load ;  SUBSYS_DIR=/workspace/subsystems/07-feeschedule ;   LOAD_TARGET=load-idx ;;
    accounts)      LOADER=/workspace/subsystems/08-account/bin/acct-load ;    SUBSYS_DIR=/workspace/subsystems/08-account ;       LOAD_TARGET=load-idx ;;
    "")
        echo "[ops-master-load] FAIL: master name required" >&2
        echo "  usage: ops-master-load.sh {calendar|branches|customers|products|interestrates|feeschedules|accounts} [--dry-run]" >&2
        exit 8
        ;;
    *)
        echo "[ops-master-load] FAIL: unknown master '$MASTER'" >&2
        exit 8
        ;;
esac

if [[ ! -x "$LOADER" ]]; then
    echo "[ops-master-load:$MASTER] FAIL: loader missing or not executable: $LOADER" >&2
    exit 1
fi

exec 9>>"$LOCK_FILE"
if ! flock -n 9; then
    echo "[ops-master-load:$MASTER] SKIP: batch in progress (flock held); operator should retry after batch completes" >&2
    exit 2
fi

PSQL_BASE="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q -t -A"
export PGPASSWORD="${PGPASSWORD:-cobol}"
TS_NOW=$(date +%Y-%m-%dT%H:%M:%S)
BDATE=$(date +%Y-%m-%d)
LOADER_BASE=$(basename -- "$LOADER")
$PSQL_BASE -v bdate="$BDATE" -v master="$MASTER" -v loader="$LOADER_BASE" <<'SQL' >/dev/null 2>&1 || true
INSERT INTO audit_log (audit_id, business_date, system_ts, subsystem, action, actor, target_type, target_id, payload_json, severity, schema_version)
VALUES (nextval('audit_id_seq'), :'bdate'::date, NOW(), '22-operations', 'OPS_MASTER_LOAD_START', 'SYSTEM', 'MASTER', :'master', jsonb_build_object('loader', :'loader'), 'I', '1.0');
SQL

if [[ "$DRY_RUN" == "--dry-run" ]]; then
    echo "[ops-master-load:$MASTER] DRY-RUN OK (loader=$LOADER_BASE; target=make -C $SUBSYS_DIR $LOAD_TARGET)"
    rc=0
else
    if make -C "$SUBSYS_DIR" "$LOAD_TARGET" >/tmp/ops-master-load-$MASTER.out 2>&1; then
        echo "[ops-master-load:$MASTER] OK"
        rc=0
    else
        rc=$?
        echo "[ops-master-load:$MASTER] FAIL rc=$rc" >&2
        head -10 /tmp/ops-master-load-$MASTER.out >&2 2>/dev/null || true
    fi
fi

if [[ "$rc" -eq 0 ]]; then
    AUDIT_ACTION=OPS_MASTER_LOAD_OK; AUDIT_SEV=I
else
    AUDIT_ACTION=OPS_MASTER_LOAD_FAIL; AUDIT_SEV=E
fi
$PSQL_BASE -v bdate="$BDATE" -v action="$AUDIT_ACTION" -v master="$MASTER" -v rc="$rc" -v sev="$AUDIT_SEV" <<'SQL' >/dev/null 2>&1 || true
INSERT INTO audit_log (audit_id, business_date, system_ts, subsystem, action, actor, target_type, target_id, payload_json, severity, schema_version)
VALUES (nextval('audit_id_seq'), :'bdate'::date, NOW(), '22-operations', :'action', 'SYSTEM', 'MASTER', :'master', jsonb_build_object('rc', :'rc'::integer), :'sev', '1.0');
SQL

exit $rc
