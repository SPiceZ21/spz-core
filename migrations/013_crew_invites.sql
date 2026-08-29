-- 013_crew_invites.sql
-- Crew invitations. An owner invites a player; the invite sits pending until
-- the player accepts or declines, the owner cancels, or it expires. Accepting
-- lets a player into a crew even when recruiting is switched off.

CREATE TABLE IF NOT EXISTS `crew_invites` (
  `id`         INT       AUTO_INCREMENT PRIMARY KEY,
  `crew_id`    INT       NOT NULL,
  `player_id`  INT       NOT NULL,           -- who was invited
  `invited_by` INT       NOT NULL,           -- owner who sent it
  `status`     ENUM('pending','accepted','declined','cancelled') NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NULL,
  `responded_at` TIMESTAMP NULL,
  FOREIGN KEY (crew_id)    REFERENCES crews(id)   ON DELETE CASCADE,
  FOREIGN KEY (player_id)  REFERENCES players(id),
  FOREIGN KEY (invited_by) REFERENCES players(id),
  INDEX idx_player_status (`player_id`, `status`),
  INDEX idx_crew_status   (`crew_id`, `status`)
);
