USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `php5`
--

CREATE TABLE `php5` (
  `php5_id` int(8) unsigned NOT NULL AUTO_INCREMENT,  
  `component_instance_id` int(8) unsigned NOT NULL,
  `php5_session_handler` enum('files','memcache') NOT NULL DEFAULT 'files',
  `php5_session_path` char (127) NOT NULL,
  PRIMARY KEY (`php5_id`),
  KEY `fk_php5_1` (`component_instance_id`),
  CONSTRAINT `fk_php5_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
