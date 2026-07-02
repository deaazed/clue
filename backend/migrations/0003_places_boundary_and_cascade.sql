-- Add boundary polygon storage to places
ALTER TABLE places ADD COLUMN IF NOT EXISTS boundary JSONB;

-- Cascade-delete memories when their place is deleted
-- (previously SET NULL — align with mobile app behaviour)
ALTER TABLE memories
  DROP CONSTRAINT IF EXISTS memories_place_id_fkey,
  ADD CONSTRAINT memories_place_id_fkey
    FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE;
