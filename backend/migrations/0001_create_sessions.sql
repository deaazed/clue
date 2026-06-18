CREATE TABLE IF NOT EXISTS sessions (
    id            UUID        PRIMARY KEY,
    started_at_ms BIGINT      NOT NULL,
    duration_ms   BIGINT      NOT NULL DEFAULT 0,
    sample_count  INT         NOT NULL DEFAULT 0,
    data          JSONB       NOT NULL,
    recorded_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS sessions_started_at_idx ON sessions (started_at_ms DESC);
