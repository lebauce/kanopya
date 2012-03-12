USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `php5`
--

CREATE TABLE `php5` (
  `php5_id` int(8) unsigned NOT NULL,  
  `php5_session_handler` enum('files','memcache') NOT NULL DEFAULT 'files',
  `php5_session_path` char (127) NOT NULL,
  PRIMARY KEY (`php5_id`),
  CONSTRAINT FOREIGN KEY (`php5_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
