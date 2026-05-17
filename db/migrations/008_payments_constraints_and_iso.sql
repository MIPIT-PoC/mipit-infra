-- 008_payments_constraints_and_iso.sql
-- P09: Add CHECK constraints + ISO 20022 columns
-- Idempotent (uses IF NOT EXISTS / DO NOTHING).

-- ───────────────────────────────────────────────────────────────────────────
-- CHECK constraints on payments
-- ───────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_status_check') THEN
    ALTER TABLE payments ADD CONSTRAINT payments_status_check
      CHECK (status IN (
        'RECEIVED', 'VALIDATED', 'CANONICALIZED', 'NORMALIZED', 'ROUTED',
        'QUEUED', 'SENT_TO_DESTINATION', 'ACKED_BY_RAIL', 'COMPLETED',
        'FAILED', 'REJECTED', 'DUPLICATE', 'COMPENSATING', 'COMPENSATED',
        'DEAD_LETTER'
      ));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_origin_rail_check') THEN
    ALTER TABLE payments ADD CONSTRAINT payments_origin_rail_check
      CHECK (origin_rail IN ('PIX', 'SPEI', 'BRE_B', 'SWIFT_MT103', 'ISO20022_MX', 'ACH_NACHA', 'FEDNOW'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_destination_rail_check') THEN
    ALTER TABLE payments ADD CONSTRAINT payments_destination_rail_check
      CHECK (destination_rail IS NULL OR destination_rail IN ('PIX', 'SPEI', 'BRE_B', 'SWIFT_MT103', 'ISO20022_MX', 'ACH_NACHA', 'FEDNOW'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_currency_iso4217') THEN
    ALTER TABLE payments ADD CONSTRAINT payments_currency_iso4217
      CHECK (currency ~ '^[A-Z]{3}$');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_amount_positive') THEN
    ALTER TABLE payments ADD CONSTRAINT payments_amount_positive
      CHECK (amount > 0);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_debtor_country_iso') THEN
    ALTER TABLE payments ADD CONSTRAINT payments_debtor_country_iso
      CHECK (debtor_country IS NULL OR debtor_country ~ '^[A-Z]{2}$');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_creditor_country_iso') THEN
    ALTER TABLE payments ADD CONSTRAINT payments_creditor_country_iso
      CHECK (creditor_country IS NULL OR creditor_country ~ '^[A-Z]{2}$');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_payment_id_format') THEN
    ALTER TABLE payments ADD CONSTRAINT payments_payment_id_format
      CHECK (payment_id ~ '^PMT-[A-Z0-9]{10,40}$');
  END IF;
END $$;

-- Remove sentinel defaults — caller must provide explicit values
ALTER TABLE payments ALTER COLUMN currency DROP DEFAULT;
ALTER TABLE payments ALTER COLUMN reference DROP DEFAULT;

-- ───────────────────────────────────────────────────────────────────────────
-- ISO 20022 columns
-- ───────────────────────────────────────────────────────────────────────────

ALTER TABLE payments ADD COLUMN IF NOT EXISTS uetr UUID;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS end_to_end_id VARCHAR(35);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS instr_id VARCHAR(35);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS tx_id VARCHAR(35);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS charge_bearer CHAR(4);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS interbank_settlement_date DATE;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS instructed_amount NUMERIC(18,5);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS instructed_currency CHAR(3);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS settlement_amount NUMERIC(18,5);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS settlement_currency CHAR(3);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS exchange_rate NUMERIC(18,8);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS exchange_rate_source VARCHAR(50);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS origin_ispb VARCHAR(8);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS origin_institution_code VARCHAR(8);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS destination_institution_code VARCHAR(8);

-- Constraints on the new ISO columns
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_charge_bearer_check') THEN
    ALTER TABLE payments ADD CONSTRAINT payments_charge_bearer_check
      CHECK (charge_bearer IS NULL OR charge_bearer IN ('DEBT','CRED','SHAR','SLEV'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_instructed_currency_iso') THEN
    ALTER TABLE payments ADD CONSTRAINT payments_instructed_currency_iso
      CHECK (instructed_currency IS NULL OR instructed_currency ~ '^[A-Z]{3}$');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_settlement_currency_iso') THEN
    ALTER TABLE payments ADD CONSTRAINT payments_settlement_currency_iso
      CHECK (settlement_currency IS NULL OR settlement_currency ~ '^[A-Z]{3}$');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_uetr_unique') THEN
    ALTER TABLE payments ADD CONSTRAINT payments_uetr_unique UNIQUE (uetr);
  END IF;
END $$;

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_payments_uetr ON payments(uetr) WHERE uetr IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payments_end_to_end_id ON payments(end_to_end_id) WHERE end_to_end_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payments_status_created ON payments(status, created_at);
