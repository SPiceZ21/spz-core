-- 030_race_entries.sql
-- One row per racer per race: the car they drove (rental or owned), how it
-- ended, and their connection and framerate DURING the race.
--   Car / class balance:  win rate per model per track, rental vs owned.
--   Lag:                  ping vs DNFs / incidents.
--   Performance:          FPS per track (avg and the worst second).
-- Written by spz-analytics when the race results land.

CREATE TABLE IF NOT EXISTS `race_entries` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `race_id`      VARCHAR(64)  NOT NULL,
  `player_id`    INT          DEFAULT NULL,
  `track`        VARCHAR(128) NOT NULL,
  `race_type`    VARCHAR(16)  DEFAULT NULL,
  `car_class`    VARCHAR(32)  DEFAULT NULL,
  `model`        VARCHAR(64)  DEFAULT NULL,
  `rental`       TINYINT(1)   DEFAULT NULL,
  `racers`       SMALLINT UNSIGNED DEFAULT NULL,
  `position`     SMALLINT UNSIGNED DEFAULT NULL,
  `dnf`          TINYINT(1)   NOT NULL DEFAULT 0,
  `dnf_reason`   VARCHAR(64)  DEFAULT NULL,
  `finish_ms`    INT UNSIGNED DEFAULT NULL,
  `best_lap_ms`  INT UNSIGNED DEFAULT NULL,
  `incidents`    SMALLINT UNSIGNED DEFAULT NULL,
  `avg_ping`     SMALLINT UNSIGNED DEFAULT NULL,
  `max_ping`     SMALLINT UNSIGNED DEFAULT NULL,
  `avg_fps`      SMALLINT UNSIGNED DEFAULT NULL,
  `min_fps`      SMALLINT UNSIGNED DEFAULT NULL,
  `created_at`   DATETIME     NOT NULL,
  INDEX `idx_entry_model`  (`model`, `track`),
  INDEX `idx_entry_track`  (`track`, `created_at`),
  INDEX `idx_entry_player` (`player_id`, `created_at`),
  INDEX `idx_entry_race`   (`race_id`)
);
