ALTER TABLE audit_log
    ADD COLUMN IF NOT EXISTS event_key VARCHAR(80);

CREATE UNIQUE INDEX IF NOT EXISTS uq_audit_event_key
    ON audit_log (business_date, event_key)
    WHERE event_key IS NOT NULL;

COMMENT ON COLUMN audit_log.event_key IS
    'Optional logical idempotency key ("<action>:<target_id>") for per-event '
    'dedup via uq_audit_event_key; NULL = not deduped (summaries / legacy).';
