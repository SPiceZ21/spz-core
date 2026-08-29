-- 011_crew_image.sql
-- Crew profile picture. Stored as a URL (Discord CDN, imgur, etc.) so the crew
-- dashboard and nametags can show a crest instead of the text tag.

ALTER TABLE `crews`
  ADD COLUMN IF NOT EXISTS `image_url` TEXT NULL AFTER `tag`;
