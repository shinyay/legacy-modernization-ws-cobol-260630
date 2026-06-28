#!/usr/bin/env bash
export PGPASSWORD="${PGPASSWORD:-cobol}"
psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q -c "DELETE FROM batch_run WHERE batch_id IN ('BATCH-CLOSED-1') OR batch_id LIKE 'BATCH-12-TEST%'" 2>/dev/null || true
psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q -c "DELETE FROM audit_log WHERE action='TXN_POSTED'" 2>/dev/null || true
psql -h ${PGHOST:-postgres} -U ${PGUSER:-cobol} -d ${PGDATABASE:-banking} -q -c "DELETE FROM audit_outbox" 2>/dev/null || true
