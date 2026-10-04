-- 034_server_events.sql
-- Server lifecycle:
--   server_start     the server booted (a start with no stop before it = crash)
--   resource_start / resource_stop   any resource, with its name
--   analytics_stop   spz-analytics itself stopping (usually a shutdown)
-- uptime_s is the server's uptime when it happened.

CREATE TABLE IF NOT EXISTS `server_events` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `event`       VARCHAR(24)  NOT NULL,
  `detail`      VARCHAR(128) DEFAULT NULL,
  `uptime_s`    INT UNSIGNED DEFAULT NULL,
  `players`     SMALLINT UNSIGNED DEFAULT NULL,
  `created_at`  DATETIME     NOT NULL,
  INDEX `idx_srv_event` (`event`, `created_at`)
);
