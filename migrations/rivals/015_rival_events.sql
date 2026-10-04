-- 015_rival_events.sql
-- Rivalry activity log. One row per time a lap beat a rival's stored best,
-- for both kinds of rivalry:
--   player : your rival's time on a track was beaten (or they beat yours)
--   crew   : a member's lap beat the rival crew's best on a track
-- The dashboards read this as a "recent activity" feed; nothing else depends
-- on it, so it can be pruned freely.

CREATE TABLE IF NOT EXISTS `rival_events` (
  `id`               INT       AUTO_INCREMENT PRIMARY KEY,
  `kind`             ENUM('player','crew') NOT NULL,
  `track`            VARCHAR(64) NOT NULL,
  `actor_player_id`  INT       NOT NULL,          -- who set the lap
  `actor_crew_id`    INT       NULL,              -- their crew, for kind = 'crew'
  `target_player_id` INT       NULL,              -- rival driver, for kind = 'player'
  `target_crew_id`   INT       NULL,              -- rival crew, for kind = 'crew'
  `new_ms`           INT       NOT NULL,
  `old_ms`           INT       NULL,
  `margin_ms`        INT       NULL,              -- old_ms - new_ms
  `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (actor_player_id) REFERENCES players(id),
  INDEX idx_kind_created  (`kind`, `created_at`),
  INDEX idx_actor         (`actor_player_id`, `created_at`),
  INDEX idx_crew_pair     (`actor_crew_id`, `target_crew_id`, `created_at`)
);
