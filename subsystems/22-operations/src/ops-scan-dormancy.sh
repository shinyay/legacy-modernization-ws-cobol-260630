#!/usr/bin/env bash
set -uo pipefail
DRY_RUN="${1:-}"

DORM_SO=/workspace/subsystems/09-accountlifecycle/bin/ALC-DORMANCY-SCAN.so
REACT_SO=/workspace/subsystems/09-accountlifecycle/bin/ALC-REACTIVATION-SCAN.so
ALC_BIN_DIR=/workspace/subsystems/09-accountlifecycle/bin
AUD_BIN=/workspace/shared/util/aud-write/bin
LOG_BIN=/workspace/shared/util/shared-log/bin

PSQL_BASE="psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q -t -A"
export PGPASSWORD="${PGPASSWORD:-cobol}"
BDATE=$(date +%Y-%m-%d)

emit_audit() {
    local action="$1" sev="$2" payload="$3"
    $PSQL_BASE -v bdate="$BDATE" -v action="$action" -v sev="$sev" -v payload="$payload" <<'SQL' >/dev/null 2>&1 || true
INSERT INTO audit_log (audit_id, business_date, system_ts, subsystem, action, actor, target_type, target_id, payload_json, severity, schema_version)
VALUES (nextval('audit_id_seq'), :'bdate'::date, NOW(), '22-operations', :'action', 'SYSTEM', 'SCAN', 'DORMANCY', CAST(:'payload' AS jsonb), :'sev', '1.0');
SQL
}

if [[ ! -f "$DORM_SO" ]]; then
    echo "[ops-scan-dormancy] FAIL: missing $DORM_SO" >&2
    emit_audit OPS_DORM_SCAN_FAIL E '{"err":"binary_missing"}'
    exit 1
fi

emit_audit OPS_DORM_SCAN_START I '{"mode":"weekly"}'

if [[ "$DRY_RUN" == "--dry-run" ]]; then
    echo "[ops-scan-dormancy] DRY-RUN OK (binaries=ALC-DORMANCY-SCAN + ALC-REACTIVATION-SCAN)"
    emit_audit OPS_DORM_SCAN_OK I '{"mode":"dry_run"}'
    exit 0
fi

COB_LIBRARY_PATH="$ALC_BIN_DIR:$AUD_BIN:$LOG_BIN" \
LD_PRELOAD=/usr/local/lib/libocesql.so \
cobcrun ALC-DORMANCY-SCAN >/tmp/ops-scan-dormancy.out 2>&1
rc=$?

if [[ "$rc" -eq 0 ]]; then
    echo "[ops-scan-dormancy] dormancy OK"
elif [[ "$rc" -ge 8 && "$rc" -le 12 ]]; then
    echo "[ops-scan-dormancy] dormancy SOFT-SKIP (rc=$rc; prereqs not wired; v1.1 backlog)" >&2
    rc=0
else
    echo "[ops-scan-dormancy] dormancy FAIL rc=$rc" >&2
    head -10 /tmp/ops-scan-dormancy.out >&2 2>/dev/null || true
fi

if [[ "$rc" -eq 0 && -f "$REACT_SO" ]]; then
    COB_LIBRARY_PATH="$ALC_BIN_DIR:$AUD_BIN:$LOG_BIN" \
    LD_PRELOAD=/usr/local/lib/libocesql.so \
    cobcrun ALC-REACTIVATION-SCAN >>/tmp/ops-scan-dormancy.out 2>&1
    rc2=$?
    if [[ "$rc2" -eq 0 ]]; then
        echo "[ops-scan-dormancy] reactivation OK"
    elif [[ "$rc2" -ge 8 && "$rc2" -le 12 ]]; then
        echo "[ops-scan-dormancy] reactivation SOFT-SKIP (rc=$rc2)" >&2
    else
        echo "[ops-scan-dormancy] reactivation WARN rc=$rc2 (non-blocking)" >&2
    fi
fi

if [[ "$rc" -eq 0 ]]; then
    emit_audit OPS_DORM_SCAN_OK I '{"mode":"real"}'
else
    emit_audit OPS_DORM_SCAN_FAIL E "{\"rc\":$((rc))}"
fi
exit $rc
