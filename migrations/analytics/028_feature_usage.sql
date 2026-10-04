-- 028_feature_usage.sql
-- Daily use counts per feature (replays opened, leaderboard opened, admin
-- race, ...). One row per day per feature: tiny, kept forever.

CREATE TABLE IF NOT EXISTS `feature_usage` (
  `day`      DATE         NOT NULL,
  `feature`  VARCHAR(48)  NOT NULL,
  `uses`     INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`day`, `feature`)
);
