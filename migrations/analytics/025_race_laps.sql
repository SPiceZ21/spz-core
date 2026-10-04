-- 025_race_laps.sql
-- Every completed lap of every finisher (circuits), with the top and average
-- speed spz-analytics sampled on that lap. Lap-time spread per track,
-- consistency per driver, pace per car class.

CREATE TABLE IF NOT EXISTS `race_laps` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `race_id`     VARCHAR(64)  NOT NULL,
  `player_id`   INT          DEFAULT NULL,
  `track`       VARCHAR(128) NOT NULL,
  `car_class`   VARCHAR(32)  DEFAULT NULL,
  `lap`         SMALLINT UNSIGNED NOT NULL,
  `lap_ms`      INT UNSIGNED NOT NULL,
  `top_kmh`     SMALLINT UNSIGNED DEFAULT NULL,
  `avg_kmh`     SMALLINT UNSIGNED DEFAULT NULL,
  `created_at`  DATETIME     NOT NULL,
  INDEX `idx_laps_track`  (`track`, `lap_ms`),
  INDEX `idx_laps_player` (`player_id`, `created_at`),
  INDEX `idx_laps_race`   (`race_id`)
);
