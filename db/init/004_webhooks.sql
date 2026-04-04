-- Migration 004: Webhook subscriptions
-- Allows clients to register a URL to receive HTTP POST notifications
-- when a payment reaches a terminal state (COMPLETED, FAILED, REJECTED).
--
-- HMAC-SHA256 signature sent in header: X-MIPIT-Signature: sha256=<hex>
-- Payload (POST body): { payment_id, status, event, timestamp, payment }

CREATE TABLE IF NOT EXISTS webhook_subscriptions (
    id               TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    payment_id       TEXT NOT NULL REFERENCES payments(payment_id) ON DELETE CASCADE,
    url              TEXT NOT NULL,
    events           TEXT[] NOT NULL DEFAULT ARRAY['COMPLETED', 'FAILED', 'REJECTED'],
    secret           TEXT,                    -- optional per-subscription secret for HMAC
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fired_at         TIMESTAMPTZ,             -- when the last delivery was attempted
    last_http_status INTEGER,                 -- HTTP status code of last delivery
    delivery_attempts INTEGER NOT NULL DEFAULT 0,
    last_error       TEXT
);

CREATE INDEX IF NOT EXISTS idx_webhook_payment_id ON webhook_subscriptions(payment_id);
CREATE INDEX IF NOT EXISTS idx_webhook_fired_at   ON webhook_subscriptions(fired_at) WHERE fired_at IS NULL;
