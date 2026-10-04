-- 008_rivals.sql
-- Rival pairings: each player is matched to another of similar iRating for
-- async competition. Assigned by spz-progression, refreshed periodically.

CREATE TABLE IF NOT EXISTS `rivals` (
  `player_id`   INT       NOT NULL PRIMARY KEY,
  `rival_id`    INT       NOT NULL,
  `assigned_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (player_id) REFERENCES players(id),
  FOREIGN KEY (rival_id)  REFERENCES players(id),
  INDEX idx_rival (rival_id)
);
