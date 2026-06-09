-- =========================
-- BlueFox V1 INIT DATABASE
-- =========================

-- Extensions utiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================
-- ROLES / PERMISSIONS
-- =========================

-- (optionnel si déjà créé dans install.sh)
-- CREATE ROLE bluefox LOGIN PASSWORD 'bluefoxpassword';

-- =========================
-- TABLES
-- =========================

CREATE TABLE IF NOT EXISTS alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID,
    rule_name TEXT,
    alert_type TEXT NOT NULL,
    severity TEXT NOT NULL,
    message TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'new',
    host TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
);

CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hostname TEXT NOT NULL,
    ip TEXT NOT NULL,
    os TEXT,
    tags TEXT[] NOT NULL DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_seen TIMESTAMPTZ,
    metadata JSONB
);

CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source TEXT NOT NULL,
    host TEXT NOT NULL,
    event_type TEXT NOT NULL,
    severity TEXT NOT NULL,
    message TEXT NOT NULL,
    tags TEXT[] NOT NULL DEFAULT '{}',
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host TEXT NOT NULL,
    metric_type TEXT NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    source TEXT NOT NULL,
    labels JSONB,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================
-- FOREIGN KEYS
-- =========================

ALTER TABLE alerts
ADD CONSTRAINT fk_event
FOREIGN KEY (event_id)
REFERENCES events(id)
ON DELETE SET NULL;

-- =========================
-- INDEXES
-- =========================

CREATE INDEX IF NOT EXISTS idx_events_timestamp ON events(timestamp);
CREATE INDEX IF NOT EXISTS idx_events_host ON events(host);

CREATE INDEX IF NOT EXISTS idx_alerts_event_id ON alerts(event_id);
CREATE INDEX IF NOT EXISTS idx_alerts_created_at ON alerts(created_at);

CREATE INDEX IF NOT EXISTS idx_metrics_timestamp ON metrics(timestamp);
CREATE INDEX IF NOT EXISTS idx_metrics_host ON metrics(host);

-- =========================
-- OWNERSHIP (clean setup)
-- =========================

ALTER TABLE alerts OWNER TO psql_bluefox;
ALTER TABLE devices OWNER TO psql_bluefox;
ALTER TABLE events OWNER TO psql_bluefox;
ALTER TABLE metrics OWNER TO psql_bluefox;

-- =========================
-- PERMISSIONS
-- =========================

GRANT ALL PRIVILEGES ON DATABASE bluefox TO psql_bluefox;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO psql_bluefox;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON TABLES TO psql_bluefox;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES TO psql_bluefox;
