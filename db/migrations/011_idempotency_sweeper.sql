-- 011_idempotency_sweeper.sql
-- P09: Function the app schedules every hour to purge expired idempotency claims.

CREATE OR REPLACE FUNCTION sweep_expired_idempotency_keys() RETURNS INTEGER AS $$
DECLARE
  deleted INTEGER;
BEGIN
  DELETE FROM idempotency_keys WHERE expires_at < NOW();
  GET DIAGNOSTICS deleted = ROW_COUNT;
  RETURN deleted;
END;
$$ LANGUAGE plpgsql;
