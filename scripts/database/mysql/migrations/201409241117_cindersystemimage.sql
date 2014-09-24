CREATE TABLE `cinder_systemimage` (
  `cinder_systemimage_id` int(8) unsigned NOT NULL,
  `image_uuid` char(64) NULL DEFAULT NULL,
  `volume_uuid` char(64) NULL DEFAULT NULL,
  PRIMARY KEY (`cinder_systemimage_id`),
  FOREIGN KEY (`cinder_systemimage_id`) REFERENCES `systemimage` (`systemimage_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


INSERT INTO class_type (class_type) VALUES ('Entity::Systemimage::CinderSystemimage');

INSERT INTO `cinder_systemimage`  (`cinder_systemimage_id`, `image_uuid`, `volume_uuid`) (
    SELECT systemimage_id, NULL, systemimage_desc FROM systemimage WHERE storage_manager_id IN
        (SELECT `open_stack_id` FROM `open_stack`)
);

UPDATE entity
SET class_type_id = (SELECT class_type_id FROM class_type
                     WHERE class_type = 'Entity::Systemimage::CinderSystemimage')
WHERE entity_id IN (SELECT cinder_systemimage_id FROM `cinder_systemimage`);

-- DOWN --
DROP TABLE IF EXISTS `cinder_systemimage`;
