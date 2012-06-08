USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `SCO`
--

CREATE TABLE `SCO` (
    `SCO_id` int(8) unsigned,
    PRIMARY KEY (`SCO_id`),
    CONSTRAINT FOREIGN KEY (`SCO_id`) REFERENCES `connector` (`connector_id`) ON DELETE CASCADE ON UPDATE NO ACTION
)   ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
