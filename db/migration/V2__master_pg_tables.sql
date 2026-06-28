CREATE TABLE accounts (
    acct_number      CHAR(13)     NOT NULL PRIMARY KEY,
    acct_name        VARCHAR(60)  NOT NULL,
    branch_code      CHAR(3)      NOT NULL,
    product_code     CHAR(3)      NOT NULL,
    acct_status      CHAR(1)      NOT NULL,
    cust_id          CHAR(10)     NOT NULL,
    opened_date      DATE         NOT NULL DEFAULT CURRENT_DATE,
    dormancy_date    DATE,
    created_at       TIMESTAMP(0) NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP(0) NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_accounts_cust   ON accounts (cust_id);
CREATE INDEX idx_accounts_branch ON accounts (branch_code);
CREATE INDEX idx_accounts_status ON accounts (acct_status);

CREATE TABLE customers (
    cust_id          CHAR(10)     NOT NULL PRIMARY KEY,
    cust_name        VARCHAR(60)  NOT NULL,
    cust_name_kana   VARCHAR(80)  NOT NULL,
    cust_status      CHAR(1)      NOT NULL,
    tier             CHAR(1)      NOT NULL DEFAULT 'B',
    phone            VARCHAR(20),
    address          VARCHAR(120),
    created_at       TIMESTAMP(0) NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP(0) NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_customers_name_kana ON customers (cust_name_kana);
CREATE INDEX idx_customers_phone     ON customers (phone);
CREATE INDEX idx_customers_status    ON customers (cust_status);

CREATE TABLE branches (
    branch_code      CHAR(3)      NOT NULL PRIMARY KEY,
    branch_name      VARCHAR(60)  NOT NULL,
    branch_name_kana VARCHAR(80)  NOT NULL,
    branch_type      CHAR(1)      NOT NULL,
    address          VARCHAR(120),
    phone            VARCHAR(20),
    created_at       TIMESTAMP(0) NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP(0) NOT NULL DEFAULT NOW()
);

CREATE TABLE products (
    product_code      CHAR(3)      NOT NULL PRIMARY KEY,
    product_name      VARCHAR(60)  NOT NULL,
    product_type      CHAR(1)      NOT NULL,
    interest_eligible CHAR(1)      NOT NULL DEFAULT 'Y',
    fee_eligible      CHAR(1)      NOT NULL DEFAULT 'Y',
    min_balance_jpy   BIGINT       NOT NULL DEFAULT 0,
    created_at        TIMESTAMP(0) NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP(0) NOT NULL DEFAULT NOW()
);

CREATE TABLE calendar (
    cal_date         DATE         NOT NULL PRIMARY KEY,
    day_type         CHAR(1)      NOT NULL,
    holiday_name     VARCHAR(60),
    fiscal_year      INTEGER      NOT NULL,
    created_at       TIMESTAMP(0) NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_calendar_day_type ON calendar (day_type);

CREATE TABLE interest_rates (
    product_code       CHAR(3)      NOT NULL,
    effective_date     DATE         NOT NULL,
    annual_rate        NUMERIC(7,6) NOT NULL,
    tier_threshold_jpy BIGINT,
    created_at         TIMESTAMP(0) NOT NULL DEFAULT NOW(),
    PRIMARY KEY (product_code, effective_date)
);

CREATE TABLE fee_schedules (
    category         CHAR(2)      NOT NULL,
    tier             CHAR(1)      NOT NULL,
    effective_date   DATE         NOT NULL,
    fee_jpy          BIGINT       NOT NULL,
    created_at       TIMESTAMP(0) NOT NULL DEFAULT NOW(),
    PRIMARY KEY (category, tier, effective_date)
);
