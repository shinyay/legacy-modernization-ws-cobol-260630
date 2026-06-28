CREATE TABLE IF NOT EXISTS audit_outbox (
    outbox_id     BIGSERIAL    PRIMARY KEY,
    business_date DATE         NOT NULL,
    system_ts     TIMESTAMP    NOT NULL DEFAULT NOW(),
    subsystem     VARCHAR(30)  NOT NULL,
    action        VARCHAR(50)  NOT NULL,
    actor         VARCHAR(30),
    target_type   VARCHAR(20),
    target_id     VARCHAR(20),
    payload_json  JSONB,
    severity      CHAR(1)      NOT NULL,
    event_key     VARCHAR(80)  NOT NULL,
    created_ts    TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_outbox_bdate
    ON audit_outbox (business_date);

COMMENT ON TABLE audit_outbox IS
    'Transactional audit outbox (#2 / v1.13.0): per-txn audit INTENTS written in '
    'the same serializable tx as the post; AUD-DRAIN relays them to audit_log '
    'idempotently (V6 event_key) then DELETEs. Transient queue, not a log.';

GRANT SELECT, INSERT, DELETE ON audit_outbox TO pb_app;
GRANT USAGE, SELECT ON SEQUENCE audit_outbox_outbox_id_seq TO pb_app;
