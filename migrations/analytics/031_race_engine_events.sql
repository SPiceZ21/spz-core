-- 031_race_engine_events.sql
-- The race engine itself. Every race-state change with how long the state it
-- left lasted (phase timings: join window, poll, spawn, warmup, countdown,
-- race), plus failures reported by spz-races:
--   state          detail = new state, duration_ms = time spent in the old one
--   spawn_fail     a racer's car never confirmed (player_id set)
--   race_abort     a cycle reset before finishing (detail = state it was in)
--   poll_no_winner / poll_no_tracks / poll_no_cars

CREATE TABLE IF NOT EXISTS `race_engine_events` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `race_id`      VARCHAR(64)  DEFAULT NULL,
  `event`        VARCHAR(32)  NOT NULL,
  `detail`       VARCHAR(128) DEFAULT NULL,
  `player_id`    INT          DEFAULT NULL,
  `players`      SMALLINT UNSIGNED DEFAULT NULL,
  `duration_ms`  INT UNSIGNED DEFAULT NULL,
  `created_at`   DATETIME     NOT NULL,
  INDEX `idx_engine_event` (`event`, `created_at`),
  INDEX `idx_engine_race`  (`race_id`)
);
