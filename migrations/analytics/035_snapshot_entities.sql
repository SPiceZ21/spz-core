-- 035_snapshot_entities.sql
-- Entity counts on the existing per-minute server_snapshots row: vehicles,
-- peds and objects the server knows about. A count that only ever climbs is
-- a leak (cars that are never cleaned up). Old rows stay NULL.

ALTER TABLE server_snapshots ADD COLUMN IF NOT EXISTS vehicles SMALLINT UNSIGNED DEFAULT NULL;

ALTER TABLE server_snapshots ADD COLUMN IF NOT EXISTS peds SMALLINT UNSIGNED DEFAULT NULL;

ALTER TABLE server_snapshots ADD COLUMN IF NOT EXISTS objects SMALLINT UNSIGNED DEFAULT NULL;
