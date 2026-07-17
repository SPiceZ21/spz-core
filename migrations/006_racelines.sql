-- 006_racelines.sql
-- spz-raceline: each player's best-lap driving line per track. The line is
-- only overwritten when the lap time improves (enforced by spz-raceline's
-- server, which takes the time from spz-races — never from the client).
-- `points` is a JSON flat array of x,y,z,state quadruples; the anchor is the
-- line's first point, used for proximity auto-loading client-side.

CREATE TABLE IF NOT EXISTS `racelines` (
  `id`         INT          AUTO_INCREMENT PRIMARY KEY,
  `player_id`  INT          NOT NULL,
  `track`      VARCHAR(64)  NOT NULL,
  `best_ms`    INT          NOT NULL,
  `anchor_x`   FLOAT        NOT NULL,
  `anchor_y`   FLOAT        NOT NULL,
  `anchor_z`   FLOAT        NOT NULL,
  `points`     MEDIUMTEXT   NOT NULL,
  `updated_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_player_track (player_id, track),
  FOREIGN KEY (player_id) REFERENCES players(id),
  INDEX idx_player (player_id)
);
