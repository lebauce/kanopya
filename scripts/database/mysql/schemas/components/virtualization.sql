USE `kanopya`;

SET foreign_key_checks=0;

CREATE TABLE `virtualization` (
    `virtualization_id` int(8) unsigned NOT NULL,
    PRIMARY KEY (`virtualization_id`),
    CONSTRAINT `fk_virtualization_1` FOREIGN KEY (`virtualization_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
