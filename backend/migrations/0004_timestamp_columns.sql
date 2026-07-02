-- Store device-side capture timestamps for round-trip restore after reinstall
ALTER TABLE places   ADD COLUMN IF NOT EXISTS timestamp_ms BIGINT;
ALTER TABLE memories ADD COLUMN IF NOT EXISTS timestamp_ms BIGINT;
