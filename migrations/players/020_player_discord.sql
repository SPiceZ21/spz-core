-- 020_player_discord.sql
-- Discord user ID, so the website can link a web login to a player row.
--
-- Written by spz-identity (LinkDiscordId in server/connect.lua) on every join
-- where FiveM reports a discord: identifier -- i.e. Discord was running on the
-- player's PC. NULL until then; existing players fill in on their next join.
--
-- UNIQUE because one Discord account maps to exactly one player. spz-identity
-- clears the ID from any other row before writing, so a player who moves to a
-- new Rockstar license takes the link with them instead of hitting the index.
-- Many NULLs are allowed under a UNIQUE index in MariaDB, as with plate in 017.

ALTER TABLE players ADD COLUMN IF NOT EXISTS discord_id VARCHAR(32) DEFAULT NULL;

ALTER TABLE `players`
  ADD UNIQUE INDEX IF NOT EXISTS `idx_discord_id` (`discord_id`);
