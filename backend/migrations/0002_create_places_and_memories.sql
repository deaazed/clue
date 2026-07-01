CREATE TABLE IF NOT EXISTS places (
    id           TEXT        PRIMARY KEY,
    name         TEXT        NOT NULL,
    lat          DOUBLE PRECISION NOT NULL,
    lng          DOUBLE PRECISION NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS places_created_at_idx ON places (created_at DESC);

CREATE TABLE IF NOT EXISTS memories (
    id           TEXT        PRIMARY KEY,
    place_id     TEXT        REFERENCES places(id) ON DELETE SET NULL,
    label        TEXT        NOT NULL,
    icon_type    TEXT        NOT NULL DEFAULT 'other',
    note         TEXT,
    lat          DOUBLE PRECISION,
    lng          DOUBLE PRECISION,
    ble_devices  JSONB       NOT NULL DEFAULT '[]',
    path         JSONB,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS memories_place_id_idx ON memories (place_id);
CREATE INDEX IF NOT EXISTS memories_created_at_idx ON memories (created_at DESC);
