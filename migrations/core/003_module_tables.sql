-- 003_module_tables.sql
-- Tables owned by feature modules. Previously these lived in per-resource .sql
-- files (or were created at runtime), which drifted out of sync with the core
-- schema — they are consolidated here.

-- spz-progression: seasonal badges (was only in spz-identity/server/db/schema.sql)
CREATE TABLE IF NOT EXISTS `player_badges` (
  `id`         INT          AUTO_INCREMENT PRIMARY KEY,
  `player_id`  INT          NOT NULL,
  `badge_id`   VARCHAR(32)  NOT NULL,
  `season_num` INT          NOT NULL,
  `awarded_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (player_id) REFERENCES players(id),
  INDEX idx_player (player_id),
  INDEX idx_badge_season (badge_id, season_num)
);

-- spz-speedcam: personal bests per camera (was created at runtime on boot)
CREATE TABLE IF NOT EXISTS `speedcam_bests` (
  `id`            INT           AUTO_INCREMENT PRIMARY KEY,
  `camera_id`     VARCHAR(32)   NOT NULL,
  `player_id`     INT           NOT NULL,
  `speed_kmh`     FLOAT         NOT NULL,
  `vehicle_model` VARCHAR(64)   NULL,
  `updated_at`    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_cam_player (camera_id, player_id),
  INDEX idx_camera (camera_id),
  INDEX idx_player (player_id)
);

-- spz-identity: crew-change cooldown (read by the crew callbacks)
ALTER TABLE players ADD COLUMN IF NOT EXISTS last_crew_change INT DEFAULT 0;
