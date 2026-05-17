-- 009_audit_events_constraints.sql
-- P09: CHECK constraint on event_type + tighten FK
-- Idempotent.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'audit_events_event_type_check') THEN
    ALTER TABLE audit_events ADD CONSTRAINT audit_events_event_type_check
      CHECK (event_type IN (
        'PAYMENT_RECEIVED', 'PAYMENT_VALIDATED', 'CANONICAL_UPDATED',
        'NORMALIZATION_COMPLETE',
        'ROUTE_DECISION', 'TRANSLATED', 'PUBLISHED_TO_QUEUE',
        'ACK_RECEIVED', 'PIPELINE_ERROR', 'STATUS_CHANGE',
        'COMPENSATION_STARTED', 'COMPENSATION_COMPLETED', 'COMPENSATION_REVERSAL_REQUIRED',
        'WEBHOOK_DELIVERED', 'WEBHOOK_FAILED',
        'RECONCILIATION_REPORT',
        'DEAD_LETTER',
        'AUDIT_TEST'
      ));
  END IF;
END $$;

-- Tighten FK: explicit ON DELETE RESTRICT (default behavior, but make it explicit)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'audit_events_payment_id_fkey'
  ) THEN
    ALTER TABLE audit_events DROP CONSTRAINT audit_events_payment_id_fkey;
  END IF;
END $$;

ALTER TABLE audit_events
  ADD CONSTRAINT audit_events_payment_id_fkey
  FOREIGN KEY (payment_id) REFERENCES payments(payment_id)
  ON DELETE RESTRICT;

-- ─── mapping_table constraints ──────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'mapping_table_rail_check') THEN
    ALTER TABLE mapping_table ADD CONSTRAINT mapping_table_rail_check
      CHECK (rail IN ('PIX', 'SPEI', 'BRE_B', 'SWIFT_MT103', 'ISO20022_MX', 'ACH_NACHA', 'FEDNOW'));
  END IF;
END $$;

-- ─── route_rules: introduce action column ───────────────
ALTER TABLE route_rules ADD COLUMN IF NOT EXISTS action VARCHAR(20) NOT NULL DEFAULT 'ROUTE';
ALTER TABLE route_rules ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'route_rules_action_check') THEN
    ALTER TABLE route_rules ADD CONSTRAINT route_rules_action_check
      CHECK (action IN ('ROUTE', 'REJECT', 'COMPENSATE'));
  END IF;
END $$;

-- Migrate the special 'fallback_unavailable' rule (which used destination_rail='FAILED'
-- as a status flag) to use the new action='REJECT' instead.
UPDATE route_rules
   SET action = 'REJECT'
 WHERE rule_name = 'fallback_unavailable'
   AND destination_rail IN ('FAILED', 'UNAVAILABLE');
