-- 039_poll_reroll_votes.sql
-- The track and car ballots end with a REROLL card ("none of these").
-- Each poll attempt stores how many players picked it on each ballot, and
-- which set was redrawn when it won. The card itself is also stored in
-- race_poll_options with option_key = 'reroll'.
--   reroll_phase  NULL (no reroll), 'track', 'vehicle' or 'both'

ALTER TABLE race_poll_runs ADD COLUMN IF NOT EXISTS track_reroll_votes SMALLINT NOT NULL DEFAULT 0;

ALTER TABLE race_poll_runs ADD COLUMN IF NOT EXISTS vehicle_reroll_votes SMALLINT NOT NULL DEFAULT 0;

ALTER TABLE race_poll_runs ADD COLUMN IF NOT EXISTS reroll_phase VARCHAR(16) DEFAULT NULL;
