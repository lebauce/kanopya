USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `apache2`
--

CREATE TABLE `apache2` (
  `component_instance_id` int(8) unsigned NOT NULL,
  `apache2_serverroot` char(64) NOT NULL,
  `apache2_loglevel` char(64) NOT NULL,
  `apache2_ports` char(32) NOT NULL,
  `apache2_sslports` char(32) NOT NULL,
  `apache2_phpsession_dir` char(64) NOT NULL,
  `apache2_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`apache2_id`),
  KEY `fk_apache2_1` (`component_instance_id`),
  CONSTRAINT `fk_apache2_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `apache2_virtualhost`
--

CREATE TABLE `apache2_virtualhost` (
  `apache2_virtualhost_id` int(8) unsigned NOT NULL,
  `apache2_id` int(8) unsigned NOT NULL,
  `apache2_virtualhost_servername` char(128) DEFAULT NULL,
  `apache2_virtualhost_sslenable` int(1) DEFAULT NULL,
  `apache2_virtualhost_serveradmin` char(64) DEFAULT NULL,
  `apache2_virtualhost_documentroot` char(128) DEFAULT NULL,
  `apache2_virtualhost_log` char(128) DEFAULT NULL,
  `apache2_virtualhost_errorlog` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`apache2_virtualhost_id`),
  KEY `fk_apache2_virtualhost_1` (`apache2_id`),
  CONSTRAINT `fk_apache2_virtualhost_1` FOREIGN KEY (`apache2_id`) REFERENCES `apache2` (`apache2_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;