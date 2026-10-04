-- 029_daily_player_stats.sql
-- Per player per day, pre-summed so dashboards over months stay fast.
-- Kept forever (one small row per active player per day).

CREATE TABLE IF NOT EXISTS `daily_player_stats` (
  `day`         DATE         NOT NULL,
  `player_id`   INT          NOT NULL,
  `playtime_s`  INT UNSIGNED NOT NULL DEFAULT 0,
  `sessions`    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `races`       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `finishes`    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `wins`        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `podiums`     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `dnfs`        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `laps`        INT UNSIGNED NOT NULL DEFAULT 0,
  `distance_m`  INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`day`, `player_id`),
  INDEX `idx_daily_player` (`player_id`, `day`)
);
