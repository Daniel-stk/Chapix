ALTER TABLE `xaa`.`xaa_users` 
ADD COLUMN `password_reset_expires` DATETIME NULL COMMENT '' AFTER `language`,
ADD COLUMN `password_reset_key` VARCHAR(45) NULL COMMENT '' AFTER `password_reset_expires`;
