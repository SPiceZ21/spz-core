-- 022_player_sessions.sql
-- One row per connection: when a player joined, when they left and why, and
-- their ping over the session. Written by spz-analytics when the player drops.
-- Daily / weekly active players, session length, peak hours, churn.
--
-- player_id is NULL only if the player left before their profile loaded.
-- Raw rows are pruned after spz-analytics Config.RetentionDays.

CREATE TABLE IF NOT EXISTS `player_sessions` (
  `id`                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `player_id`         INT          DEFAULT NULL,
  `started_at`        DATETIME     NOT NULL,
  `ended_at`          DATETIME     NOT NULL,
  `duration_s`        INT UNSIGNED NOT NULL DEFAULT 0,
  `disconnect_reason` VARCHAR(128) DEFAULT NULL,
  `avg_ping`          SMALLINT UNSIGNED DEFAULT NULL,
  `max_ping`          SMALLINT UNSIGNED DEFAULT NULL,
  `first_session`     TINYINT(1)   NOT NULL DEFAULT 0,
  INDEX `idx_sess_started` (`started_at`),
  INDEX `idx_sess_player`  (`player_id`, `started_at`)
);
