-- 026_server_snapshots.sql
-- The server once a minute: who is online and what they are doing, active
-- routing buckets, average ping, the server's own frame time and race state.

CREATE TABLE IF NOT EXISTS `server_snapshots` (
  `taken_at`        DATETIME     NOT NULL PRIMARY KEY,
  `players_online`  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `in_race`         SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `in_queue`        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `in_timetrial`    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `in_minigame`     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `in_replay`       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `spectating`      SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `freeroam`        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `buckets_active`  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `avg_ping`        SMALLINT UNSIGNED DEFAULT NULL,
  `frame_ms`        DECIMAL(6,2) DEFAULT NULL,
  `race_state`      VARCHAR(16)  DEFAULT NULL
);
