ALTER TABLE `masterimage` ADD `storage_manager_id` int(8) unsigned DEFAULT NULL;
ALTER TABLE `masterimage` ADD INDEX ( `storage_manager_id` );
ALTER TABLE `masterimage` ADD FOREIGN KEY ( `storage_manager_id` ) REFERENCES `kanopya`.`component` (
`component_id`
) ON DELETE NO ACTION ON UPDATE NO ACTION ;


UPDATE masterimage
    SET storage_manager_id =
        (SELECT component_id FROM component WHERE component_type_id =
            (SELECT component_type_id FROM component_type WHERE component_name = 'HCMStorageManager' LIMIT 1)
        LIMIT 1);

-- DOWN --