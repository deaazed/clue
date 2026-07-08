-- Place-type clues can be traced like places
ALTER TABLE memories ADD COLUMN IF NOT EXISTS boundary JSONB;
