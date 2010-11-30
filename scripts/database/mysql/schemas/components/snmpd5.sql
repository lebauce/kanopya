USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `snmpd5`
--

CREATE TABLE `snmpd5` (
  `component_instance_id` int(8) unsigned NOT NULL,
  `monitor_server_ip` char(39) NOT NULL,
  `snmpd_options` char(128) NOT NULL,
  PRIMARY KEY (`component_instance_id`),
  KEY `fk_snmpd5_1` (`component_instance_id`),
  CONSTRAINT `fk_snmpd5_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
