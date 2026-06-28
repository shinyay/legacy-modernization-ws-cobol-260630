CREATE OR REPLACE FUNCTION create_audit_partition(p_start text)
RETURNS text
LANGUAGE plpgsql
AS $func$
DECLARE
    d_start     date := p_start::date;
    d_end       date := (d_start + interval '1 month')::date;
    v_part_name text := 'audit_log_' || to_char(d_start, 'YYYYMM');
BEGIN
    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS public.%I '
        || 'PARTITION OF public.audit_log FOR VALUES FROM (%L) TO (%L)',
        v_part_name, d_start, d_end
    );
    RETURN v_part_name;
END
$func$;

COMMENT ON FUNCTION create_audit_partition(text) IS
    'Idempotently create audit_log monthly partition (end=start+1mo); '
    'identifier/literal quoted via format(%I,%L). Replaces COBOL psql '
    'shell-out (#79).';

CREATE OR REPLACE FUNCTION detach_expired_audit_partitions(p_horizon text)
RETURNS integer
LANGUAGE plpgsql
AS $func$
DECLARE
    d_horizon  date := p_horizon::date;
    r          record;
    v_end_text text;
    v_end      date;
    v_count    integer := 0;
BEGIN
    FOR r IN
        SELECT c.relname AS pn,
               pg_get_expr(c.relpartbound, c.oid) AS bound
        FROM pg_inherits i
        JOIN pg_class c ON c.oid = i.inhrelid
        WHERE i.inhparent = 'public.audit_log'::regclass
          AND c.relname ~ '^audit_log_[0-9]{6}$'
    LOOP
        v_end_text := substring(r.bound from $re$TO \('([0-9-]+)'\)$re$);
        IF v_end_text IS NULL THEN
            CONTINUE;   -- not a simple range bound (e.g. MAXVALUE); skip safely
        END IF;
        v_end := v_end_text::date;
        IF v_end <= d_horizon THEN
            EXECUTE format('ALTER TABLE public.audit_log DETACH PARTITION public.%I', r.pn);
            v_count := v_count + 1;
        END IF;
    END LOOP;
    RETURN v_count;
END
$func$;

COMMENT ON FUNCTION detach_expired_audit_partitions(text) IS
    'Detach audit_log monthly partitions with end<=horizon; identifier '
    'quoted via format(%I). Replaces COBOL bash detach shell-out (#79).';

REVOKE ALL ON FUNCTION create_audit_partition(text)                  FROM PUBLIC;
REVOKE ALL ON FUNCTION detach_expired_audit_partitions(text)         FROM PUBLIC;
GRANT EXECUTE ON FUNCTION create_audit_partition(text)               TO cobol;
GRANT EXECUTE ON FUNCTION detach_expired_audit_partitions(text)      TO cobol;
