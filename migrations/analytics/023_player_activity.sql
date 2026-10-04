-- 023_player_activity.sql
-- Time spent in one mode, back to back for the whole session:
-- freeroam, queue, race, timetrial, spectate, replay, pursuit, hideseek,
-- colorrush (or "minigame" for anything unlisted). Where playtime goes.

CREATE TABLE IF NOT EXISTS `player_activity` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `player_id`   INT          DEFAULT NULL,
  `mode`        VARCHAR(32)  NOT NULL,
  `started_at`  DATETIME     NOT NULL,
  `ended_at`    DATETIME     NOT NULL,
  `duration_s`  INT UNSIGNED NOT NULL DEFAULT 0,
  INDEX `idx_act_mode`   (`mode`, `started_at`),
  INDEX `idx_act_player` (`player_id`, `started_at`)
);
