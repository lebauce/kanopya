USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `kanopyacollector1`
--

CREATE TABLE `kanopyacollector1` (
    `kanopyacollector1_id` int(8) unsigned NOT NULL,
    `time_step` int(8) unsigned NOT NULL,
    `storage_duration` int(8) unsigned NOT NULL,
    `rrd_base_directory` char(255) NOT NULL,
    PRIMARY KEY (`kanopyacollector1_id`),
    CONSTRAINT FOREIGN KEY (`kanopyacollector1_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
)   ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
