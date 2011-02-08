USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `syslogng3`
--

CREATE TABLE `syslogng3` (
  `syslogng3_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `component_instance_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`syslogng3_id`),
  KEY `fk_syslogng3_1` (`component_instance_id`),
  CONSTRAINT `fk_syslogng3_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `syslogng3_entry`
-- An entry of conf can be 'source', 'destination' or 'filter'
--

CREATE TABLE `syslogng3_entry` (
  `syslogng3_entry_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `syslogng3_entry_name` char(32) NOT NULL,
  `syslogng3_entry_type` enum('source', 'destination', 'filter') NOT NULL,
  `syslogng3_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`syslogng3_entry_id`),
  KEY `fk_syslogng3_entry_1` (`syslogng3_id`),
  CONSTRAINT `fk_syslogng3_entry_1` FOREIGN KEY (`syslogng3_id`) REFERENCES `syslogng3` (`syslogng3_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `syslogng3_entry_param`
-- One param is store in only one text field (content):
-- for entry 'source' or 'destination': param is a driver and its args (ex: "file('/var/log')" or "udp( ip(x.x.x.x) port(xxx) )"
-- for entry 'filter': param is an expression (ex: "host('routeur') and program('squid')")
--

CREATE TABLE `syslogng3_entry_param` (
  `syslogng3_entry_param_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `syslogng3_entry_param_content` text(512) NOT NULL,
  `syslogng3_entry_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`syslogng3_entry_param_id`),
  KEY `fk_syslogng3_entry_param_1` (`syslogng3_entry_id`),
  CONSTRAINT `fk_syslogng3_entry_param_1` FOREIGN KEY (`syslogng3_entry_id`) REFERENCES `syslogng3_entry` (`syslogng3_entry_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `syslogng3_log`
-- represents a log entry in the conf file, i.e an association of entries (source, destination, filter)
--

CREATE TABLE `syslogng3_log` (
  `syslogng3_log_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `syslogng3_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`syslogng3_log_id`),
  KEY `fk_syslogng3_log_1` (`syslogng3_id`),
  CONSTRAINT `fk_syslogng3_log_1` FOREIGN KEY (`syslogng3_id`) REFERENCES `syslogng3` (`syslogng3_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `syslogng3_log_param`
-- effective association between one log and one entry
--

CREATE TABLE `syslogng3_log_param` (
  `syslogng3_log_param_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `syslogng3_log_id` int(8) unsigned NOT NULL,
  `syslogng3_log_param_entrytype` char(32) NOT NULL,
  `syslogng3_log_param_entryname` char(32) NOT NULL,
  PRIMARY KEY (`syslogng3_log_param_id`),
  KEY `fk_syslogng3_log_param_1` (`syslogng3_log_id`),
  CONSTRAINT `fk_syslogng3_log_param_1` FOREIGN KEY (`syslogng3_log_id`) REFERENCES `syslogng3_log` (`syslogng3_log_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
