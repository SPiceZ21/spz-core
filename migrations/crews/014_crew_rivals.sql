-- 014_crew_rivals.sql
-- Crew rivalries. Mirrors the per-player `rivals` table: each crew is paired
-- with another of similar average iRating for async crew-vs-crew competition.
-- Assigned by spz-crew, refreshed periodically.

CREATE TABLE IF NOT EXISTS `crew_rivals` (
  `crew_id`       INT       NOT NULL PRIMARY KEY,
  `rival_crew_id` INT       NOT NULL,
  `assigned_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (crew_id)       REFERENCES crews(id) ON DELETE CASCADE,
  FOREIGN KEY (rival_crew_id) REFERENCES crews(id) ON DELETE CASCADE,
  INDEX idx_rival_crew (`rival_crew_id`)
);
