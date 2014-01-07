USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `kanopya_front`
--

CREATE TABLE `kanopya_front` (
    `kanopya_front_id` int(8) unsigned NOT NULL,
    PRIMARY KEY (`kanopya_front_id`),
    CONSTRAINT FOREIGN KEY (`kanopya_front_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
)   ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `kanopya_executor`
--

CREATE TABLE `kanopya_executor` (
    `kanopya_executor_id` int(8) unsigned NOT NULL,
    `control_queue` char(255) DEFAULT NULL,
    `time_step` int(8) unsigned NOT NULL,
    `masterimages_directory` char(255) NOT NULL,
    `clusters_directory` char(255) NOT NULL,
    `private_directory` char(255) NOT NULL,
    PRIMARY KEY (`kanopya_executor_id`),
    CONSTRAINT FOREIGN KEY (`kanopya_executor_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
)   ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `kanopya_aggregator`
--

CREATE TABLE `kanopya_aggregator` (
    `kanopya_aggregator_id` int(8) unsigned NOT NULL,
    `control_queue` char(255) DEFAULT NULL,
    `time_step` int(8) unsigned NOT NULL,
    `storage_duration` int(8) unsigned NOT NULL,
    PRIMARY KEY (`kanopya_aggregator_id`),
    CONSTRAINT FOREIGN KEY (`kanopya_aggregator_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
)   ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `kanopya_rules_engine`
--

CREATE TABLE `kanopya_rules_engine` (
    `kanopya_rules_engine_id` int(8) unsigned NOT NULL,
    `control_queue` char(255) DEFAULT NULL,
    `time_step` int(8) unsigned NOT NULL,
    PRIMARY KEY (`kanopya_rules_engine_id`),
    CONSTRAINT FOREIGN KEY (`kanopya_rules_engine_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
)   ENGINE=InnoDB DEFAULT CHARSET=utf8;


SET foreign_key_checks=1;
