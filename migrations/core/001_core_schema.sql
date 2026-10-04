-- 001_core_schema.sql
-- Canonical SPiceZ core tables. Applied once, tracked in spz_migrations.

CREATE TABLE IF NOT EXISTS `players` (
  `id`               INT           AUTO_INCREMENT PRIMARY KEY,
  `identifier`       VARCHAR(64)   NOT NULL UNIQUE,
  `citizen_id`       VARCHAR(16)   NOT NULL UNIQUE,
  `username`         VARCHAR(64)   NULL,
  `gender`           TINYINT       NULL,
  `first_time`       TINYINT       DEFAULT 1,
  `playtime`         INT           DEFAULT 0,
  `xp`               INT           DEFAULT 0,
  `class_points`     INT           DEFAULT 0,
  `alltime_points`   INT           DEFAULT 0,
  `sr`               FLOAT         DEFAULT 2.0,
  `i_rating`         INT           DEFAULT 1500,
  `rank`             VARCHAR(8)    DEFAULT 'C-5',
  `license_tier`     TINYINT       DEFAULT 0,
  `top3_count`       INT           DEFAULT 0,
  `crew_id`          INT           NULL,
  `credits`          INT           DEFAULT 0,
  `banned`           TINYINT       DEFAULT 0,
  `ban_reason`       VARCHAR(255)  NULL,
  `avatar_url`       TEXT          NULL,
  `banner_url`       TEXT          NULL,
  `created_at`       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  `last_seen`        TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_identifier (identifier),
  INDEX idx_citizen_id  (citizen_id),
  INDEX idx_rank       (rank),
  INDEX idx_license    (license_tier)
);

CREATE TABLE IF NOT EXISTS `crews` (
  `id`          INT           AUTO_INCREMENT PRIMARY KEY,
  `name`        VARCHAR(64)   NOT NULL UNIQUE,
  `tag`         VARCHAR(4)    NOT NULL,
  `owner_id`    INT           NOT NULL,
  `crew_outfit` JSON          NULL,
  `created_at`  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES players(id)
);

CREATE TABLE IF NOT EXISTS `driver_licenses` (
  `id`           INT         AUTO_INCREMENT PRIMARY KEY,
  `player_id`    INT         NOT NULL,
  `tier`         TINYINT     NOT NULL,
  `unlocked_at`  TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
  `method`       VARCHAR(32) DEFAULT 'xp_threshold',
  FOREIGN KEY (player_id) REFERENCES players(id),
  INDEX idx_player (player_id)
);

CREATE TABLE IF NOT EXISTS `vehicle_customizations` (
  `id`         INT         AUTO_INCREMENT PRIMARY KEY,
  `player_id`  INT         NOT NULL,
  `model`      VARCHAR(64) NOT NULL,
  `preset`     JSON        NOT NULL,
  `updated_at` TIMESTAMP   DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_player_model (player_id, model),
  FOREIGN KEY (player_id) REFERENCES players(id),
  INDEX idx_player (player_id)
);

CREATE TABLE IF NOT EXISTS `race_sessions` (
  `id`           INT         AUTO_INCREMENT PRIMARY KEY,
  `race_id`      VARCHAR(64) NOT NULL UNIQUE,
  `track`        VARCHAR(64) NOT NULL,
  `car_class`    TINYINT     NOT NULL,
  `player_count` TINYINT     NOT NULL,
  `duration_ms`  INT,
  `created_at`   TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS `race_results` (
  `id`             INT         AUTO_INCREMENT PRIMARY KEY,
  `race_id`        VARCHAR(64) NOT NULL,
  `player_id`      INT         NOT NULL,
  `position`       TINYINT     NOT NULL,
  `finish_time`    INT,
  `best_lap`       INT,
  `points_earned`  INT         DEFAULT 0,
  `sr_change`      FLOAT       DEFAULT 0,
  `irating_change` INT         DEFAULT 0,
  `personal_best`  TINYINT     DEFAULT 0,
  `dnf`            TINYINT     DEFAULT 0,
  `created_at`     TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (player_id) REFERENCES players(id),
  INDEX idx_race   (race_id),
  INDEX idx_player (player_id)
);

CREATE TABLE IF NOT EXISTS `track_records` (
  `id`         INT         AUTO_INCREMENT PRIMARY KEY,
  `track`      VARCHAR(64) NOT NULL,
  `car_class`  TINYINT     NOT NULL,
  `player_id`  INT         NOT NULL,
  `best_time`  INT         NOT NULL,
  `set_at`     TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (player_id) REFERENCES players(id),
  UNIQUE KEY uq_track_class_player (track, car_class, player_id),
  INDEX idx_track (track, car_class)
);

CREATE TABLE IF NOT EXISTS `economy_transactions` (
  `id`         INT          AUTO_INCREMENT PRIMARY KEY,
  `player_id`  INT          NOT NULL,
  `amount`     INT          NOT NULL,
  `balance`    INT          NOT NULL,
  `reason`     VARCHAR(128),
  `created_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (player_id) REFERENCES players(id),
  INDEX idx_player (player_id)
);

CREATE TABLE IF NOT EXISTS `player_outfits` (
  `id`         INT         AUTO_INCREMENT PRIMARY KEY,
  `player_id`  INT         NOT NULL UNIQUE,
  `outfit`     JSON        NOT NULL,
  `updated_at` TIMESTAMP   DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (player_id) REFERENCES players(id)
);

