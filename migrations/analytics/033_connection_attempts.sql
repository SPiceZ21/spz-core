-- 033_connection_attempts.sql
-- Every connection attempt and how it ended:
--   joined      made it into the server (load_ms = connect -> spawned in game)
--   rejected    turned away at the door (reason: whitelist, no Discord,
--               profile error, ban, ...)
--   abandoned   started connecting but never joined (closed the game,
--               timed out, dropped while loading)
-- player_id is filled when the license matches a known player.

CREATE TABLE IF NOT EXISTS `connection_attempts` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `player_id`    INT          DEFAULT NULL,
  `outcome`      VARCHAR(16)  NOT NULL,
  `reason`       VARCHAR(160) DEFAULT NULL,
  `wait_ms`      INT UNSIGNED DEFAULT NULL,
  `load_ms`      INT UNSIGNED DEFAULT NULL,
  `created_at`   DATETIME     NOT NULL,
  INDEX `idx_conn_outcome` (`outcome`, `created_at`),
  INDEX `idx_conn_player`  (`player_id`, `created_at`)
);
