-- 037_daily_credit_balances.sql
-- Every recently active player's credit balance, once a day. Where money
-- piles up and how fast the economy inflates (economy_transactions already
-- holds the individual payments). Kept forever.

CREATE TABLE IF NOT EXISTS `daily_credit_balances` (
  `day`        DATE         NOT NULL,
  `player_id`  INT          NOT NULL,
  `credits`    BIGINT       NOT NULL DEFAULT 0,
  PRIMARY KEY (`day`, `player_id`),
  INDEX `idx_credits_player` (`player_id`, `day`)
);
