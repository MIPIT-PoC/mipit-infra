-- MiPIT PoC — Schema principal
-- Ejecutado automáticamente al iniciar el contenedor postgres

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── Tabla payments ─────────────────────────────────
CREATE TABLE payments (
    payment_id       TEXT PRIMARY KEY,
    idempotency_key  TEXT UNIQUE,
    status           TEXT NOT NULL DEFAULT 'RECEIVED',
    origin_rail      TEXT NOT NULL,
    destination_rail TEXT,
    amount           NUMERIC(18,2) NOT NULL,
    currency         TEXT NOT NULL DEFAULT 'USD',
    fx_source_currency TEXT,
    fx_target_currency TEXT,
    fx_rate          NUMERIC(18,8),
    debtor_alias     TEXT NOT NULL,
    debtor_name      TEXT,
    debtor_country   TEXT,
    creditor_alias   TEXT NOT NULL,
    creditor_name    TEXT,
    creditor_country TEXT,
    purpose          TEXT DEFAULT 'P2P',
    reference        TEXT DEFAULT 'MIPIT-POC',
    origin_payload   JSONB,
    canonical_payload JSONB,
    translated_payload JSONB,
    rail_ack         JSONB,
    route_rule_applied TEXT,
    trace_id         TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    validated_at     TIMESTAMPTZ,
    canonicalized_at TIMESTAMPTZ,
    routed_at        TIMESTAMPTZ,
    queued_at        TIMESTAMPTZ,
    sent_at          TIMESTAMPTZ,
    acked_at         TIMESTAMPTZ,
    completed_at     TIMESTAMPTZ,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_created_at ON payments(created_at);
CREATE INDEX idx_payments_idempotency ON payments(idempotency_key);
CREATE INDEX idx_payments_origin_rail ON payments(origin_rail);
CREATE INDEX idx_payments_destination_rail ON payments(destination_rail);

-- ─── Tabla audit_events ─────────────────────────────
CREATE TABLE audit_events (
    id               BIGSERIAL PRIMARY KEY,
    payment_id       TEXT NOT NULL REFERENCES payments(payment_id),
    event_type       TEXT NOT NULL,
    stage            TEXT NOT NULL,
    status           TEXT NOT NULL,
    detail           JSONB,
    trace_id         TEXT,
    adapter_id       TEXT,
    instance_id      TEXT,
    latency_ms       INTEGER,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_payment_id ON audit_events(payment_id);
CREATE INDEX idx_audit_stage ON audit_events(stage);
CREATE INDEX idx_audit_created_at ON audit_events(created_at);

-- ─── Tabla route_rules ──────────────────────────────
CREATE TABLE route_rules (
    id               SERIAL PRIMARY KEY,
    rule_name        TEXT NOT NULL UNIQUE,
    condition_field  TEXT NOT NULL,
    condition_value  TEXT NOT NULL,
    destination_rail TEXT NOT NULL,
    priority         INTEGER NOT NULL DEFAULT 1,
    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    description      TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Tabla mapping_table ────────────────────────────
CREATE TABLE mapping_table (
    id               SERIAL PRIMARY KEY,
    rail             TEXT NOT NULL,
    direction        TEXT NOT NULL CHECK (direction IN ('TO_CANONICAL', 'FROM_CANONICAL')),
    source_field     TEXT NOT NULL,
    target_field     TEXT NOT NULL,
    transformation   TEXT NOT NULL DEFAULT 'copy',
    validation_rule  TEXT,
    notes            TEXT,
    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(rail, direction, source_field)
);

-- ─── Tabla idempotency_keys ─────────────────────────
CREATE TABLE idempotency_keys (
    idempotency_key  TEXT PRIMARY KEY,
    payment_id       TEXT NOT NULL REFERENCES payments(payment_id),
    request_hash     TEXT NOT NULL,
    response_status  INTEGER,
    response_body    JSONB,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at       TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours')
);

CREATE INDEX idx_idempotency_expires ON idempotency_keys(expires_at);
