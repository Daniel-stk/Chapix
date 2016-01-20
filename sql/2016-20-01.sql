ALTER TABLE `xaa`.`xaa_domains` 
ADD COLUMN `address` TEXT NULL COMMENT '' AFTER `language`,
ADD COLUMN `phone` TEXT NULL COMMENT '' AFTER `address`;
