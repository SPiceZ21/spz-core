-- 021_race_replays.sql
-- Race replays recorded by spz-replay.
--
-- One row per race. The listing columns (track, winner, duration, ...) are
-- plain columns so the replay browser never has to touch the heavy part.
--
--   racers  JSON text: [{ id, name, crew, model, colours, plate, pos, time }]
--           `id` is the index each racer's frame track has in `frames`.
--   frames  the recorded tracks, delta-encoded text (see spz-replay
--           server/codec.lua), stored through MariaDB COMPRESS() so a typical
--           5-minute, 10-car race is a few hundred KB instead of a few MB.
--           Read back with UNCOMPRESS(frames).
--
-- spz-replay keeps only the newest Config.KeepReplays rows; older ones are
-- deleted after every save, so this table does not grow without bound.

CREATE TABLE IF NOT EXISTS `race_replays` (
  `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `race_id`      VARCHAR(64)  NOT NULL,
  `track`        VARCHAR(128) NOT NULL,
  `track_id`     VARCHAR(128) DEFAULT NULL,
  `race_type`    VARCHAR(16)  NOT NULL DEFAULT 'circuit',
  `laps`         SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `car_class`    VARCHAR(64)  DEFAULT NULL,
  `duration_ms`  INT UNSIGNED NOT NULL DEFAULT 0,
  `interval_ms`  SMALLINT UNSIGNED NOT NULL DEFAULT 100,
  `racer_count`  TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `winner`       VARCHAR(64)  DEFAULT NULL,
  `racers`       LONGTEXT     NOT NULL,
  `frames`       LONGBLOB     NOT NULL,
  `size_bytes`   INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_replay_race` (`race_id`),
  INDEX `idx_replay_created` (`created_at`),
  INDEX `idx_replay_track` (`track_id`)
);
