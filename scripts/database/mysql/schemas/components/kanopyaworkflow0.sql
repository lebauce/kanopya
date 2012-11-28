USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table
--

CREATE TABLE `kanopyaworkflow0` (
    `kanopyaworkflow_id` int(8) unsigned,
    PRIMARY KEY (`kanopyaworkflow_id`),
    CONSTRAINT FOREIGN KEY (`kanopyaworkflow_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
)   ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
