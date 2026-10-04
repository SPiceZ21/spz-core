-- 012_crew_settings.sql
-- Editable crew profile fields, owned by the crew dashboard's Settings tab.
--   description : short blurb shown on the crew card and in Browse
--   colour      : hex accent used for the crest and crew rows
--   recruiting  : 0 closes the crew to new joins (invites/owner only)

ALTER TABLE `crews`
  ADD COLUMN IF NOT EXISTS `description` VARCHAR(160) NULL AFTER `image_url`;

ALTER TABLE `crews`
  ADD COLUMN IF NOT EXISTS `colour` VARCHAR(7) NULL AFTER `description`;

ALTER TABLE `crews`
  ADD COLUMN IF NOT EXISTS `recruiting` TINYINT NOT NULL DEFAULT 1 AFTER `colour`;
