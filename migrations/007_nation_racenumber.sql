-- 007_nation_racenumber.sql
-- F1-style racer identity: nation flag (ISO 3166-1 alpha-2, lowercase) and a
-- personal race number (1-99). Number uniqueness is enforced by spz-identity
-- at creation time, not by the schema, so existing players can stay NULL.

ALTER TABLE players ADD COLUMN IF NOT EXISTS nation VARCHAR(2) DEFAULT NULL;
ALTER TABLE players ADD COLUMN IF NOT EXISTS race_number TINYINT UNSIGNED DEFAULT NULL;
