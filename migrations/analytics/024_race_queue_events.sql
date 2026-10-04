-- 024_race_queue_events.sql
-- The race funnel, one row per step: queue_join, queue_leave (left before the
-- race), race_start, finish (detail = position), dnf (detail = reason).
-- Shows where players drop out between joining and finishing.

CREATE TABLE IF NOT EXISTS `race_queue_events` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `race_id`     VARCHAR(64)  DEFAULT NULL,
  `player_id`   INT          DEFAULT NULL,
  `event`       VARCHAR(24)  NOT NULL,
  `detail`      VARCHAR(64)  DEFAULT NULL,
  `created_at`  DATETIME     NOT NULL,
  INDEX `idx_rqe_event`  (`event`, `created_at`),
  INDEX `idx_rqe_race`   (`race_id`),
  INDEX `idx_rqe_player` (`player_id`, `created_at`)
);
