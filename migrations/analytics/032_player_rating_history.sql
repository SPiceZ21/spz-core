-- 032_player_rating_history.sql
-- A player's ratings after every race that changed them, with the change:
-- iRating, Safety Rating, rank and license tier. Progression graphs and
-- promotion / demotion timelines. Kept forever (one row per player per race).

CREATE TABLE IF NOT EXISTS `player_rating_history` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `player_id`       INT          NOT NULL,
  `race_id`         VARCHAR(64)  DEFAULT NULL,
  `irating`         INT          DEFAULT NULL,
  `irating_change`  INT          DEFAULT NULL,
  `sr`              DECIMAL(5,2) DEFAULT NULL,
  `sr_change`       DECIMAL(5,2) DEFAULT NULL,
  `rank_title`      VARCHAR(16)  DEFAULT NULL,
  `rank_before`     VARCHAR(16)  DEFAULT NULL,
  `license_tier`    TINYINT      DEFAULT NULL,
  `license_before`  TINYINT      DEFAULT NULL,
  `created_at`      DATETIME     NOT NULL,
  INDEX `idx_rating_player` (`player_id`, `created_at`)
);
