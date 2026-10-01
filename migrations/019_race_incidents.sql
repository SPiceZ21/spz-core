-- Persist hard impacts already detected during races so Grafana can analyze
-- per-player crash frequency, severity, timing, and map locations.
CREATE TABLE IF NOT EXISTS `race_incidents` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `race_id` VARCHAR(64) NOT NULL,
  `player_id` INT NOT NULL,
  `elapsed_ms` INT UNSIGNED NOT NULL DEFAULT 0,
  `speed_kmh` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `speed_drop_kmh` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `x` DOUBLE NOT NULL,
  `y` DOUBLE NOT NULL,
  `z` DOUBLE NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_incident_player_time` (`player_id`, `created_at`),
  INDEX `idx_incident_race` (`race_id`),
  INDEX `idx_incident_location` (`x`, `y`),
  CONSTRAINT `fk_race_incidents_player` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`)
);
