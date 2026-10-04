-- 004_identity_columns.sql
-- Player columns spz-identity used to ALTER in at boot from its own thread,
-- which raced the core schema (players did not exist yet on a fresh database).
-- last_crew_change is repeated from 003 harmlessly: IF NOT EXISTS makes it a
-- no-op on databases that already applied it.

ALTER TABLE players ADD COLUMN IF NOT EXISTS level INT DEFAULT 1;
ALTER TABLE players ADD COLUMN IF NOT EXISTS top3_in_class_c INT DEFAULT 0;
ALTER TABLE players ADD COLUMN IF NOT EXISTS top3_in_class_b INT DEFAULT 0;
ALTER TABLE players ADD COLUMN IF NOT EXISTS top3_in_class_a INT DEFAULT 0;
ALTER TABLE players ADD COLUMN IF NOT EXISTS top3_in_class_s INT DEFAULT 0;
ALTER TABLE players ADD COLUMN IF NOT EXISTS last_race_at INT DEFAULT 0;
ALTER TABLE players ADD COLUMN IF NOT EXISTS last_race_track VARCHAR(64) DEFAULT NULL;
ALTER TABLE players ADD COLUMN IF NOT EXISTS sr_daily_gain FLOAT DEFAULT 0;
ALTER TABLE players ADD COLUMN IF NOT EXISTS sr_daily_loss FLOAT DEFAULT 0;
ALTER TABLE players ADD COLUMN IF NOT EXISTS sr_day_marker INT DEFAULT 0;
ALTER TABLE players ADD COLUMN IF NOT EXISTS login_streak INT DEFAULT 0;
ALTER TABLE players ADD COLUMN IF NOT EXISTS last_login_date VARCHAR(16) DEFAULT NULL;
ALTER TABLE players ADD COLUMN IF NOT EXISTS same_track_count INT DEFAULT 0;
ALTER TABLE players ADD COLUMN IF NOT EXISTS last_crew_change INT DEFAULT 0;
