#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR=/etc/systemd/system
ENABLE=0
START=0

for arg in "$@"; do
    case "$arg" in
        --enable) ENABLE=1 ;;
        --start)  ENABLE=1; START=1 ;;
        *)        echo "[install] unknown arg: $arg" >&2; exit 8 ;;
    esac
done

if ! command -v systemctl >/dev/null 2>&1; then
    echo "[install] FAIL: systemctl not found; not a systemd system" >&2
    echo "[install] HINT: this script is for bare-metal Linux production install only." >&2
    echo "[install] HINT: for Docker devcontainer use, invoke 'make batch-daily' directly." >&2
    exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
    echo "[install] FAIL: must run as root (= sudo)" >&2
    exit 1
fi

UNITS=(
    practice-bank-batch-daily.timer
    practice-bank-batch-daily.service
    practice-bank-batch-monthly.timer
    practice-bank-batch-monthly.service
    practice-bank-autodebit-retry.timer
    practice-bank-autodebit-retry.service
    practice-bank-dormancy-scan.timer
    practice-bank-dormancy-scan.service
    practice-bank-partition-rollover.timer
    practice-bank-partition-rollover.service
)

for unit in "${UNITS[@]}"; do
    src="$SCRIPT_DIR/$unit"
    dst="$TARGET_DIR/$unit"
    if [[ ! -f "$src" ]]; then
        echo "[install] FAIL: missing source file $src" >&2
        exit 1
    fi
    cp "$src" "$dst"
    chmod 644 "$dst"
    echo "[install] copied $unit"
done

echo "[install] reloading systemd daemon"
systemctl daemon-reload

if [[ "$ENABLE" -eq 1 ]]; then
    TIMERS=(
        practice-bank-batch-daily.timer
        practice-bank-batch-monthly.timer
        practice-bank-autodebit-retry.timer
        practice-bank-dormancy-scan.timer
        practice-bank-partition-rollover.timer
    )
    for t in "${TIMERS[@]}"; do
        echo "[install] enabling $t"
        systemctl enable "$t"
        if [[ "$START" -eq 1 ]]; then
            echo "[install] starting $t"
            systemctl start "$t"
        fi
    done
fi

echo "[install] done. Verify with:"
echo "         systemctl list-timers | grep practice-bank"
echo "         journalctl -u practice-bank-batch-daily -f"
