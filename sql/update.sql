ALTER TABLE `contacts_stages` ADD `referer` TEXT  NULL  AFTER `tag`;
ALTER TABLE `contacts_stages` ADD `campaign` VARCHAR(155)  NULL  DEFAULT NULL  AFTER `referer`;
ALTER TABLE `contacts_stages_history` ADD `referer` TEXT  NULL  AFTER `tag`;
ALTER TABLE `contacts_stages_history` ADD `campaign` VARCHAR(155)  NULL  DEFAULT NULL  AFTER `referer`;
