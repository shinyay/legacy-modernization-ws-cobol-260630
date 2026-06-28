CREATE TABLE transactions (
    txn_id                 CHAR(18)     NOT NULL PRIMARY KEY,
    business_date          DATE         NOT NULL,
    system_ts              TIMESTAMP(0) NOT NULL,
    category               CHAR(2)      NOT NULL,
    account_number         CHAR(13)     NOT NULL,
    counter_account_number CHAR(13),
    amount_jpy             BIGINT       NOT NULL,
    currency               CHAR(3)      NOT NULL,
    description            VARCHAR(120),
    source_system          VARCHAR(20)  NOT NULL,
    source_batch_id        CHAR(14)     NOT NULL,
    source_seq             INTEGER      NOT NULL,
    status                 CHAR(2)      NOT NULL,
    reversal_of            CHAR(18),
    created_by             VARCHAR(20)  NOT NULL,
    created_ts             TIMESTAMP(0) NOT NULL DEFAULT NOW(),
    CONSTRAINT txn_amount_positive CHECK (amount_jpy > 0),
    CONSTRAINT txn_currency_jpy    CHECK (currency = 'JPY'),
    CONSTRAINT txn_status_enum     CHECK (status IN ('PT','SE','RV')),
    CONSTRAINT txn_reversal_pair   CHECK ((status = 'RV') = (reversal_of IS NOT NULL))
);
CREATE UNIQUE INDEX uq_txn_source_batch_seq ON transactions (source_batch_id, source_seq);
CREATE INDEX idx_txn_bd_acct ON transactions (business_date, account_number);
CREATE INDEX idx_txn_acct_bd ON transactions (account_number, business_date);
CREATE UNIQUE INDEX uq_txn_reversal_of_when_rv ON transactions (reversal_of) WHERE status = 'RV';

CREATE TABLE postings (
    posting_id      CHAR(20)     NOT NULL PRIMARY KEY,
    txn_id          CHAR(18)     NOT NULL,
    line_no         SMALLINT     NOT NULL,
    account_number  CHAR(13)     NOT NULL,
    debit_jpy       BIGINT       NOT NULL DEFAULT 0,
    credit_jpy      BIGINT       NOT NULL DEFAULT 0,
    posting_role    CHAR(2)      NOT NULL,
    business_date   DATE         NOT NULL,
    created_ts      TIMESTAMP(0) NOT NULL DEFAULT NOW(),
    CONSTRAINT pst_amounts_nonneg CHECK (debit_jpy >= 0 AND credit_jpy >= 0),
    CONSTRAINT pst_dr_xor_cr      CHECK ((debit_jpy = 0) <> (credit_jpy = 0)),
    CONSTRAINT pst_role_enum      CHECK (posting_role IN ('DR','CR')),
    CONSTRAINT fk_pst_txn FOREIGN KEY (txn_id) REFERENCES transactions(txn_id)
);
CREATE UNIQUE INDEX uq_pst_txn_line ON postings (txn_id, line_no);
CREATE INDEX idx_pst_acct_bd ON postings (account_number, business_date);
CREATE INDEX idx_pst_txn ON postings (txn_id);

CREATE TABLE balances (
    account_number      CHAR(13)     NOT NULL PRIMARY KEY,
    balance_jpy         BIGINT       NOT NULL,
    available_jpy       BIGINT       NOT NULL,
    hold_jpy            BIGINT       NOT NULL DEFAULT 0,
    last_txn_id         CHAR(18),
    last_business_date  DATE,
    updated_ts          TIMESTAMP(0) NOT NULL DEFAULT NOW(),
    CONSTRAINT bal_hold_nonneg CHECK (hold_jpy >= 0)
);

CREATE TABLE audit_log (
    audit_id        BIGSERIAL    PRIMARY KEY,
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
    CONSTRAINT aud_severity_enum CHECK (severity IN ('I','W','E','C'))
);

CREATE TABLE interest_accruals (
    accrual_id      BIGSERIAL    PRIMARY KEY,
    business_date   DATE         NOT NULL,
    account_number  CHAR(13)     NOT NULL,
    product_code    CHAR(3)      NOT NULL,
    principal_jpy   BIGINT       NOT NULL,
    rate            NUMERIC(5,4) NOT NULL,
    days            SMALLINT     NOT NULL,
    accrued_jpy     BIGINT       NOT NULL,
    status          CHAR(2)      NOT NULL,
    posted_txn_id   CHAR(18),
    created_ts      TIMESTAMP(0) NOT NULL DEFAULT NOW(),
    CONSTRAINT iac_status_enum CHECK (status IN ('AC','PT','CN'))
);
CREATE UNIQUE INDEX uq_iac_bd_acct ON interest_accruals (business_date, account_number);
CREATE INDEX idx_iac_status_bd ON interest_accruals (status, business_date);

CREATE TABLE autodebit_schedules (
    instruction_id        CHAR(20)     NOT NULL PRIMARY KEY,
    payer_account         CHAR(13)     NOT NULL,
    payee_name            VARCHAR(80)  NOT NULL,
    amount_jpy            BIGINT       NOT NULL,
    frequency             CHAR(1)      NOT NULL,
    next_due_date         DATE         NOT NULL,
    status                CHAR(2)      NOT NULL,
    last_attempt_date     DATE,
    last_attempt_result   CHAR(2),
    consecutive_failures  SMALLINT     NOT NULL DEFAULT 0,
    created_ts            TIMESTAMP(0) NOT NULL DEFAULT NOW(),
    updated_ts            TIMESTAMP(0) NOT NULL DEFAULT NOW(),
    CONSTRAINT ad_frequency_enum CHECK (frequency IN ('M','W','D')),
    CONSTRAINT ad_status_enum    CHECK (status IN ('AC','SP','TM'))
);
CREATE INDEX idx_ad_status_due ON autodebit_schedules (status, next_due_date);
CREATE INDEX idx_ad_payer ON autodebit_schedules (payer_account);

CREATE TABLE batch_run (
    batch_id            CHAR(14)     NOT NULL PRIMARY KEY,
    business_date       DATE         NOT NULL,
    started_ts          TIMESTAMP(0) NOT NULL,
    completed_ts        TIMESTAMP(0),
    status              CHAR(2)      NOT NULL,
    current_step        VARCHAR(20),
    last_failed_step    VARCHAR(20),
    txns_posted         INTEGER,
    interest_accounts   INTEGER,
    errors_count        INTEGER      NOT NULL DEFAULT 0,
    notes               TEXT,
    CONSTRAINT br_status_enum CHECK (status IN ('RN','OK','FL','AB'))
);
CREATE INDEX idx_br_bd ON batch_run (business_date);
CREATE INDEX idx_br_status ON batch_run (status);
