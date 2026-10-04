-- 010_leaderboard_indexes.sql
-- Indexes for the leaderboard tablet's My-stats queries.
--
-- The heatmap and per-track summary both scan a single player's results over a
-- date range and join race_sessions on race_id. race_results only had a plain
-- (player_id) index, so those scans read every row a player ever set before
-- filtering by date.

ALTER TABLE `race_results`
  ADD INDEX IF NOT EXISTS `idx_player_date` (`player_id`, `created_at`);

-- race_sessions.race_id is already covered by its UNIQUE constraint, so the
-- join side needs nothing extra.

-- Track records are read per (track, car_class) by the Records tab.
ALTER TABLE `track_records`
  ADD INDEX IF NOT EXISTS `idx_track_class_time` (`track`, `car_class`, `best_time`);
