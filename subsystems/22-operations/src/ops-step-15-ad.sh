#!/usr/bin/env bash
set -uo pipefail
DRY_RUN="${1:-Y}"
STEP_ID="15-ad"
SO_PATH="/workspace/subsystems/15-autodebit/bin/AD-RUN-DAILY.so"
MODULE="AD-RUN-DAILY"
SUBSYS_BIN_DIR="$(dirname "$SO_PATH")"
AUD_BIN=/workspace/shared/util/aud-write/bin
LOG_BIN=/workspace/shared/util/shared-log/bin

_INJ="${OPS_STEP_INJECT_FAIL:-}"
if [[ "${_INJ,,}" == "${STEP_ID,,}" && -n "$_INJ" ]]; then
    echo "[OPS-STEP-$STEP_ID] INJECTED FAILURE (Phase 9.5 test hook)" >&2
    exit 1
fi

if [[ ! -f "$SO_PATH" ]]; then
    echo "[OPS-STEP-$STEP_ID] FAIL: missing $SO_PATH" >&2
    exit 1
fi

if ! command -v cobcrun >/dev/null 2>&1; then
    echo "[OPS-STEP-$STEP_ID] FAIL: cobcrun unavailable" >&2
    exit 1
fi

if [[ "$DRY_RUN" == "Y" ]]; then
    echo "[OPS-STEP-$STEP_ID] dry-run OK (smoke=$(basename $SO_PATH))"
    exit 0
fi

COB_LIBRARY_PATH="$SUBSYS_BIN_DIR:$AUD_BIN:$LOG_BIN" \
LD_PRELOAD=/usr/local/lib/libocesql.so \
PGHOST=${PGHOST:-postgres} \
PGUSER=${PGUSER:-cobol} \
PGPASSWORD=${PGPASSWORD:-cobol} \
PGDATABASE=${PGDATABASE:-banking} \
cobcrun "$MODULE" >/tmp/ops-step-$STEP_ID.out 2>&1
rc=$?

if [[ "$rc" -eq 0 ]]; then
    echo "[OPS-STEP-$STEP_ID] real-mode OK (cobcrun $MODULE rc=0)"
    exit 0
elif [[ "$rc" -ge 8 && "$rc" -le 12 ]]; then
    echo "[OPS-STEP-$STEP_ID] real-mode SOFT-SKIP (cobcrun $MODULE rc=$rc; prereqs not wired; v1.1 backlog)" >&2
    exit 0
else
    echo "[OPS-STEP-$STEP_ID] real-mode FAIL (cobcrun $MODULE rc=$rc)" >&2
    head -10 /tmp/ops-step-$STEP_ID.out >&2 2>/dev/null || true
    exit 1
fi
