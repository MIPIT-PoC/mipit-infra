-- 005_resilience.sql
-- Adds support for compensation, DLQ, and settlement tracking

-- New timestamp columns for expanded payment lifecycle
ALTER TABLE payments ADD COLUMN IF NOT EXISTS compensated_at TIMESTAMPTZ;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS dead_letter_at TIMESTAMPTZ;

-- Update the status check (payments table uses TEXT, no enum constraint needed)
-- Status values: RECEIVED, VALIDATED, CANONICALIZED, NORMALIZED, ROUTED, QUEUED,
--   SENT_TO_DESTINATION, ACKED_BY_RAIL, COMPLETED, FAILED, REJECTED, DUPLICATE,
--   COMPENSATING, COMPENSATED, DEAD_LETTER

-- Index for compensation batch queries
CREATE INDEX IF NOT EXISTS idx_payments_compensation
  ON payments(status) WHERE status IN ('DEAD_LETTER', 'FAILED');

-- Index for reconciliation window queries
CREATE INDEX IF NOT EXISTS idx_payments_created_status
  ON payments(created_at, status);

-- Update milestone timestamp query to handle new statuses
-- This is handled by the application's SQL in queries/index.ts
