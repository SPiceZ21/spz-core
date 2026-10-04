-- History for each race poll attempt, including discarded rerolls.
CREATE TABLE IF NOT EXISTS `race_poll_runs` (
  `id`             BIGINT       AUTO_INCREMENT PRIMARY KEY,
  `poll_id`        VARCHAR(64)  NOT NULL,
  `attempt`        TINYINT      NOT NULL DEFAULT 0,
  `race_type`      VARCHAR(16)  NOT NULL,
  `started_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ended_at`       TIMESTAMP    NULL,
  `eligible_count` SMALLINT     NOT NULL DEFAULT 0,
  `voter_count`    SMALLINT     NOT NULL DEFAULT 0,
  `rerolled`       TINYINT      NOT NULL DEFAULT 0,
  `track_winner`   VARCHAR(64)  NULL,
  `vehicle_winner` VARCHAR(64)  NULL,
  `traffic_winner` VARCHAR(16)  NULL,
  `cop_chase`      TINYINT      NULL,
  `cop_chase_yes`  SMALLINT     NOT NULL DEFAULT 0,
  `cop_chase_no`   SMALLINT     NOT NULL DEFAULT 0,
  UNIQUE KEY `uq_poll_attempt` (`poll_id`, `attempt`),
  INDEX `idx_poll_started` (`started_at`)
);

CREATE TABLE IF NOT EXISTS `race_poll_options` (
  `id`          BIGINT       AUTO_INCREMENT PRIMARY KEY,
  `poll_id`     VARCHAR(64)  NOT NULL,
  `attempt`     TINYINT      NOT NULL,
  `phase`       VARCHAR(16)  NOT NULL,
  `option_key`  VARCHAR(96)  NOT NULL,
  `vote_count`  SMALLINT     NOT NULL DEFAULT 0,
  `winner`      TINYINT      NOT NULL DEFAULT 0,
  INDEX `idx_poll_option` (`poll_id`, `attempt`, `phase`)
);
