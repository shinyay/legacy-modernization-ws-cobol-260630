DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pb_audit_writer') THEN
        CREATE ROLE pb_audit_writer NOLOGIN INHERIT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pb_app') THEN
        CREATE ROLE pb_app NOLOGIN INHERIT;
    END IF;
END
$$;

GRANT INSERT          ON audit_log TO pb_audit_writer;
GRANT USAGE           ON SEQUENCE audit_id_seq TO pb_audit_writer;
GRANT SELECT          ON audit_log TO pb_audit_writer; -- for slow-INSERT debug

GRANT SELECT, INSERT, UPDATE, DELETE
    ON transactions, postings, balances,
       interest_accruals, autodebit_schedules, batch_run,
       accounts, customers, branches, products,
       calendar, interest_rates, fee_schedules
    TO pb_app;

GRANT SELECT ON audit_log TO pb_app;

GRANT pb_audit_writer TO cobol;
GRANT pb_app TO cobol;
