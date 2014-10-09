ALTER TABLE `masterimage` ADD UNIQUE (`masterimage_name`);
ALTER TABLE `masterimage` ADD UNIQUE (`masterimage_file`);

-- DOWN --
ALTER TABLE `masterimage` DROP INDEX `masterimage_name`;
ALTER TABLE `masterimage` DROP INDEX `masterimage_file`;
