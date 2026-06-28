DROP TABLE audit_log;

CREATE SEQUENCE audit_id_seq;

CREATE TABLE audit_log (
    audit_id        BIGINT       NOT NULL DEFAULT nextval('audit_id_seq'),
    business_date   DATE         NOT NULL,
    system_ts       TIMESTAMP(0) NOT NULL DEFAULT NOW(),
    subsystem       VARCHAR(30)  NOT NULL,
    action          VARCHAR(50)  NOT NULL,
    actor           VARCHAR(30)  NOT NULL,
    target_type     VARCHAR(20)  NOT NULL,
    target_id       VARCHAR(20)  NOT NULL,
    payload_json    JSONB,
    severity        CHAR(1)      NOT NULL,
    schema_version  VARCHAR(10)  NOT NULL DEFAULT '1.0',
    PRIMARY KEY (business_date, audit_id),
    CONSTRAINT aud_severity_enum CHECK (severity IN ('I','W','E','C'))
) PARTITION BY RANGE (business_date);

CREATE TABLE audit_log_202606 PARTITION OF audit_log
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE audit_log_202607 PARTITION OF audit_log
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');

CREATE INDEX idx_audit_log_action    ON audit_log (action);
CREATE INDEX idx_audit_log_subsystem ON audit_log (subsystem);
CREATE INDEX idx_audit_log_target    ON audit_log (target_type, target_id);
CREATE INDEX idx_audit_log_payload_acct
    ON audit_log ((payload_json ->> 'account_number'));
