-- 036_admin_actions.sql
-- Audit log of admin actions: every action spz-admin logs (kick, goto, bring,
-- freeze, DNF, unqueue, announce, weather, clear vehicles, ...), /adminmode
-- on/off, /srace and replay deletions. Kept forever.

CREATE TABLE IF NOT EXISTS `admin_actions` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `admin_id`    INT          DEFAULT NULL,
  `admin_name`  VARCHAR(64)  DEFAULT NULL,
  `action`      VARCHAR(64)  NOT NULL,
  `detail`      VARCHAR(255) DEFAULT NULL,
  `created_at`  DATETIME     NOT NULL,
  INDEX `idx_admin_action` (`action`, `created_at`),
  INDEX `idx_admin_who`    (`admin_id`, `created_at`)
);
