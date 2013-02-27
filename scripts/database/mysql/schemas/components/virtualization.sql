USE `kanopya`;

SET foreign_key_checks=0;

CREATE TABLE `virtualization` (
    `virtualization_id` int(8) unsigned NOT NULL,
    `overcommitment_cpu_factor` double unsigned NOT NULL DEFAULT '1',
    `overcommitment_memory_factor` double unsigned NOT NULL DEFAULT '1',
    PRIMARY KEY (`virtualization_id`),
    CONSTRAINT `fk_virtualization_1` FOREIGN KEY (`virtualization_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
