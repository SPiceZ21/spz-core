-- 038_rank_points.sql
-- Ranking v3: rank is derived from one number, rank_points (RP), owned by
-- spz-progression. rank / license_tier stay as derived caches of it.
-- rank_awards is the per-race ledger: idempotency (a race is scored once per
-- player), audit, admin void, and the source for rating history.

ALTER TABLE players ADD COLUMN IF NOT EXISTS rank_points INT NOT NULL DEFAULT 0;
ALTER TABLE players ADD COLUMN IF NOT EXISTS rank_streak SMALLINT NOT NULL DEFAULT 0;
ALTER TABLE players ADD COLUMN IF NOT EXISTS rp_day_gain INT NOT NULL DEFAULT 0;
ALTER TABLE players ADD COLUMN IF NOT EXISTS rp_day_key CHAR(10) DEFAULT NULL;

CREATE TABLE IF NOT EXISTS `rank_awards` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `race_id`     VARCHAR(64)  NOT NULL,
  `player_id`   INT          NOT NULL,
  `n_field`     INT          NOT NULL,
  `position`    INT          NOT NULL,
  `rp_before`   INT          NOT NULL,
  `rp_after`    INT          NOT NULL,
  `delta`       INT          NOT NULL,
  `breakdown`   VARCHAR(255) DEFAULT NULL,
  `rules_ver`   SMALLINT     NOT NULL,
  `voided`      TINYINT      NOT NULL DEFAULT 0,
  `created_at`  DATETIME     NOT NULL,
  UNIQUE KEY `uq_award` (`race_id`, `player_id`),
  INDEX `idx_award_player` (`player_id`, `created_at`)
);

-- Backfill once: existing players keep their class and land inside it
-- (class floor + half their old class points, capped below the next class).
UPDATE players SET rank_points = LEAST(
    CASE license_tier WHEN 1 THEN 250 WHEN 2 THEN 1150 WHEN 3 THEN 3850 ELSE 0 END
      + FLOOR(COALESCE(class_points, 0) * 0.5),
    CASE license_tier WHEN 1 THEN 1149 WHEN 2 THEN 3849 WHEN 3 THEN 2000000000 ELSE 249 END
  )
WHERE rank_points = 0;
