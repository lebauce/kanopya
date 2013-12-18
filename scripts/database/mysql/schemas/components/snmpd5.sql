USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `snmpd5`
--

CREATE TABLE `snmpd5` (
  `snmpd5_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`snmpd5_id`),
  CONSTRAINT FOREIGN KEY (`snmpd5_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
