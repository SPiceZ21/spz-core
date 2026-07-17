-- 005_track_sectors.sql
-- Best sector time per player, per track, per class. Sectors themselves are
-- derived from each track's checkpoint count at runtime (see
-- spz-races/shared/sectors.lua) — only the times are persisted.

CREATE TABLE IF NOT EXISTS `track_sectors` (
  `id`        INT         AUTO_INCREMENT PRIMARY KEY,
  `player_id` INT         NOT NULL,
  `track`     VARCHAR(64) NOT NULL,
  `car_class` TINYINT     NOT NULL,
  `sector`    TINYINT     NOT NULL,
  `best_ms`   INT         NOT NULL,
  `set_at`    TIMESTAMP   DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_player_track_class_sector (player_id, track, car_class, sector),
  FOREIGN KEY (player_id) REFERENCES players(id),
  INDEX idx_track (track, car_class, sector)
);
