USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `haproxy1`
--

CREATE TABLE `haproxy1` (
  `haproxy1_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`haproxy1_id`),
  CONSTRAINT `fk_haproxy1_1` FOREIGN KEY (`haproxy1_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `haproxy1_listen`
--

CREATE TABLE `haproxy1_listen` (
  `listen_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `haproxy1_id` int(8) unsigned NOT NULL,
  `listen_name` char(64) NOT NULL,
  `listen_ip` char(17) NOT NULL DEFAULT '0.0.0.0',
  `listen_port` int(8) NOT NULL,
  `listen_mode` enum('tcp','http') NOT NULL DEFAULT 'tcp',
  `listen_balance` enum('roundrobin') NOT NULL DEFAULT 'roundrobin',
  `component_id` int(8) unsigned NOT NULL,
  `component_port` int(8) unsigned NOT NULL,
  PRIMARY KEY (`listen_id`),
  CONSTRAINT `fk_haproxy1_listen_1` FOREIGN KEY (`haproxy1_id`) REFERENCES `haproxy1` (`haproxy1_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY `fk_haproxy1_listen_2` (`component_id`),
  CONSTRAINT `fk_haproxy1_listen_2` FOREIGN KEY (`component_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
