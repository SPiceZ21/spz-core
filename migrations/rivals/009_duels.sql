-- 009_duels.sql
-- spz-races Ghost Duels: async PvP wagers. A challenger stakes credits and races
-- an opponent's STORED best line (a ghost) on a track; beating the opponent's
-- stored time wins the pot. One row per settled duel — the credit ledger and
-- audit trail. Stakes/payouts themselves move on the players.credits column and
-- are mirrored in economy_transactions by the settle logic.

CREATE TABLE IF NOT EXISTS `duels` (
  `id`            INT          AUTO_INCREMENT PRIMARY KEY,
  `challenger_id` INT          NOT NULL,
  `opponent_id`   INT          NOT NULL,
  `track`         VARCHAR(64)  NOT NULL,
  `stake`         INT          NOT NULL,
  `target_ms`     INT          NOT NULL,          -- opponent's stored best_ms
  `result_ms`     INT          NULL,              -- challenger's measured lap (NULL until finished)
  `outcome`       ENUM('pending','win','loss','void') NOT NULL DEFAULT 'pending',
  `created_at`    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  `settled_at`    TIMESTAMP    NULL,
  FOREIGN KEY (challenger_id) REFERENCES players(id),
  FOREIGN KEY (opponent_id)   REFERENCES players(id),
  INDEX idx_challenger (challenger_id),
  INDEX idx_opponent (opponent_id)
);
