-- 010_updated_at_trigger.sql
-- P09: Maintain updated_at automatically on row update.

CREATE OR REPLACE FUNCTION update_updated_at() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payments_updated_at ON payments;
CREATE TRIGGER payments_updated_at
  BEFORE UPDATE ON payments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS route_rules_updated_at ON route_rules;
CREATE TRIGGER route_rules_updated_at
  BEFORE UPDATE ON route_rules
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
