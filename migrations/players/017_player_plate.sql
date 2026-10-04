-- 017_player_plate.sql
-- Personal vanity number plate, applied to every car the player spawns.
--
-- Eight characters because that is the hard limit GTA renders on a plate;
-- anything longer is silently truncated by the game, so the column matches the
-- engine rather than letting the database accept text that can never display.
--
-- NULL means "no custom plate" and the car keeps whatever the game or its saved
-- customization preset gave it. Existing players stay NULL, so nothing changes
-- for anyone who never sets one.
--
-- Uniqueness IS enforced here, unlike race_number in 007. A race number is
-- checked by spz-identity at creation time because it is assigned once during
-- character creation; a plate can be changed at any time by any player, so two
-- people racing to claim the same text is a real collision the schema should
-- refuse rather than something every call site has to remember to check.
-- The index is on the column as stored, so claiming is case-sensitive --
-- spz-identity upper-cases before writing, which is also what GTA displays.

ALTER TABLE players ADD COLUMN IF NOT EXISTS plate VARCHAR(8) DEFAULT NULL;

-- A UNIQUE index still permits many NULLs in MySQL/MariaDB, which is exactly
-- what is wanted: every player without a plate stays NULL without colliding.
ALTER TABLE `players`
  ADD UNIQUE INDEX IF NOT EXISTS `idx_plate` (`plate`);
