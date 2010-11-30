USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for atftpd0
--

CREATE TABLE `atftpd0` (
  `atftpd0_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `component_instance_id` int(8) unsigned NOT NULL,
  `atftpd0_options` char(128) DEFAULT NULL,
  `atftpd0_use_inetd` char(32) DEFAULT NULL,
  `atftpd0_logfile` char(128) DEFAULT NULL,
  `atftpd0_repository` char(64) DEFAULT NULL,
  PRIMARY KEY (`atftpd0_id`),
  KEY `fk_atftpd0_1` (`component_instance_id`),
  CONSTRAINT `fk_atftpd0_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;