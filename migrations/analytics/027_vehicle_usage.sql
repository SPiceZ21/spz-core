-- 027_vehicle_usage.sql
-- A stint of one player driving one car in one mode: how long and how far.
-- `model` is the spawn name when spz-vehicles spawned the car, otherwise the
-- model hash as text. Most-driven cars and classes, distance per car.

CREATE TABLE IF NOT EXISTS `vehicle_usage` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `player_id`   INT          DEFAULT NULL,
  `model`       VARCHAR(64)  NOT NULL,
  `mode`        VARCHAR(32)  NOT NULL,
  `started_at`  DATETIME     NOT NULL,
  `ended_at`    DATETIME     NOT NULL,
  `seconds`     INT UNSIGNED NOT NULL DEFAULT 0,
  `distance_m`  INT UNSIGNED NOT NULL DEFAULT 0,
  INDEX `idx_veh_model`  (`model`, `started_at`),
  INDEX `idx_veh_player` (`player_id`, `started_at`)
);
