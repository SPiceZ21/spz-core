-- 002_race_columns.sql
-- Column additions for the race engine / leaderboard.

ALTER TABLE race_sessions ADD COLUMN IF NOT EXISTS track_type VARCHAR(16) NOT NULL AFTER track;
ALTER TABLE race_sessions ADD COLUMN IF NOT EXISTS laps TINYINT NOT NULL AFTER track_type;

ALTER TABLE race_results ADD COLUMN IF NOT EXISTS lap_times JSON AFTER best_lap;
ALTER TABLE race_results ADD COLUMN IF NOT EXISTS sr_change FLOAT DEFAULT 0 AFTER points_earned;
ALTER TABLE race_results ADD COLUMN IF NOT EXISTS irating_change INT DEFAULT 0 AFTER sr_change;
ALTER TABLE race_results ADD COLUMN IF NOT EXISTS xp_earned INT DEFAULT 0 AFTER irating_change;
ALTER TABLE race_results ADD COLUMN IF NOT EXISTS dnf_reason VARCHAR(32) NULL AFTER dnf;

ALTER TABLE track_records ADD COLUMN IF NOT EXISTS track_type VARCHAR(16) NOT NULL AFTER track;
ALTER TABLE track_records ADD COLUMN IF NOT EXISTS best_lap INT AFTER best_time;
