#!/usr/bin/env bash

set -euo pipefail

source /etc/profile.d/cobol.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

hr()    { printf '%s\n' "----------------------------------------------------------------"; }
step()  { printf '\n\033[1;36m[%s]\033[0m %s\n' "$1" "$2"; }
ok()    { printf '  \033[1;32m✓\033[0m %s\n' "$*"; }
fail()  { printf '  \033[1;31m✗\033[0m %s\n' "$*"; }
warn()  { printf '  \033[1;33m!\033[0m %s\n' "$*"; }

hr
echo "  cobol-in-practice-2607 post-create checks"
hr

step "1/6" "Tool versions"

cobc --version | head -2 | sed 's/^/  /'
ok "GnuCOBOL present"

if command -v ocesql > /dev/null 2>&1; then
    ocesql --version 2>&1 | head -2 | sed 's/^/  /' || true
    ok "OCESQL present at $(command -v ocesql)"
else
    fail "OCESQL not found on PATH — *.pco precompile will fail"
fi

gcc --version | head -1 | sed 's/^/  /'
make --version | head -1 | sed 's/^/  /'
psql --version | sed 's/^/  /'
git --version | sed 's/^/  /'
jq --version | sed 's/^/  /'
command -v gh >/dev/null 2>&1 && gh --version | head -1 | sed 's/^/  /' || warn "gh CLI not installed (devcontainer feature pending?)"

step "2/6" "PostgreSQL readiness (host=${PGHOST}, user=${PGUSER}, db=${PGDATABASE})"

PG_READY=0
for i in $(seq 1 30); do
    if pg_isready -h "${PGHOST}" -p "${PGPORT:-5432}" -U "${PGUSER}" -d "${PGDATABASE}" -t 2 >/dev/null 2>&1; then
        ok "postgres ready after ${i} attempt(s)"
        PG_READY=1
        break
    fi
    printf '  ... waiting for postgres (%d/30)\n' "$i"
    sleep 2
done
if [ "${PG_READY}" -ne 1 ]; then
    fail "postgres did not become ready in 60s"
    exit 1
fi

if PGCONNECT_TIMEOUT=5 psql -h "${PGHOST}" -U "${PGUSER}" -d "${PGDATABASE}" -tAc "SELECT 'pg-ok-' || version();" >/dev/null 2>&1; then
    ok "psql SELECT succeeded"
else
    fail "psql SELECT failed (auth or network)"
    exit 1
fi

step "3/6" "RabbitMQ readiness (host=${RABBITMQ_HOST}, mgmt-port=${RABBITMQ_MGMT_PORT:-15672})"

MQ_READY=0
for i in $(seq 1 30); do
    if curl -fsS -u "${RABBITMQ_USER}:${RABBITMQ_PASS}" \
            "http://${RABBITMQ_HOST}:${RABBITMQ_MGMT_PORT:-15672}/api/overview" \
            >/dev/null 2>&1; then
        ok "rabbitmq mgmt API ready after ${i} attempt(s)"
        MQ_READY=1
        break
    fi
    printf '  ... waiting for rabbitmq (%d/30)\n' "$i"
    sleep 2
done
if [ "${MQ_READY}" -ne 1 ]; then
    fail "rabbitmq did not become ready in 60s"
    exit 1
fi

step "4/6" "Hello COBOL compile + run"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TMPDIR}"' EXIT

cat > "${TMPDIR}/hello.cob" <<'EOF'
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HELLO.
       PROCEDURE DIVISION.
           DISPLAY "Hello from GnuCOBOL on " FUNCTION CURRENT-DATE.
           STOP RUN.
EOF

if cobc -x -free -o "${TMPDIR}/hello" "${TMPDIR}/hello.cob"; then
    ok "compile succeeded"
else
    fail "compile failed"
    exit 1
fi

if "${TMPDIR}/hello"; then
    ok "execution succeeded"
else
    fail "execution failed"
    exit 1
fi

step "5/6" "COBOL env vars (system-wide via /etc/profile.d/cobol.sh)"
printf '  COB_COPY_DIR      = %s\n' "${COB_COPY_DIR:-(unset)}"
printf '  COB_LIBRARY_PATH  = %s\n' "${COB_LIBRARY_PATH:-(unset)}"
printf '  COB_FILE_PATH     = %s\n' "${COB_FILE_PATH:-(unset)}"
printf '  COB_CFLAGS        = %s\n' "${COB_CFLAGS:-(unset)}"
printf '  COB_LDFLAGS       = %s\n' "${COB_LDFLAGS:-(unset)}"
printf '  LD_LIBRARY_PATH   = %s\n' "${LD_LIBRARY_PATH:-(unset)}"

step "6/6" "Fresh-env bootstrap (make setup: migrate + build-all + load-idx + seed)"
if make -C "${REPO_ROOT}" setup; then
    ok "schema migrated, subsystems built, ISAM loaded, system accounts seeded"
else
    fail "make setup failed — fix the error above, then run:  cd /workspace && make setup"
    exit 1
fi

hr
echo "  ✅ ALL CHECKS PASSED — cobol-in-practice-2607 ready"
echo "     Try:  cd console && make run-screen   (operator console; type BMON)"
hr
