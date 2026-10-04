-- 016_race_number_range.sql
-- Widen the race number from 1-99 to 1-999.
--
-- 007 declared the column TINYINT UNSIGNED, which tops out at 255 — so even
-- three-digit numbers that passed validation would have been truncated on
-- write. SMALLINT UNSIGNED (0-65535) covers the new range with room to spare.
--
-- Uniqueness is still enforced by spz-identity at creation time rather than by
-- the schema, so existing players keep their number and NULLs stay legal.

ALTER TABLE players MODIFY COLUMN race_number SMALLINT UNSIGNED DEFAULT NULL;
