USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `haproxy1`
--

CREATE TABLE `haproxy1` (
  `haproxy1_id` int(8) unsigned NOT NULL AUTO_INCREMENT,  
  `component_instance_id` int(8) unsigned NOT NULL,
  `haproxy1_http_frontend_port` int(8) NOT NULL,
  `haproxy1_http_backend_port` int(8) NOT NULL,
  `haproxy1_https_frontend_port` int(8) NOT NULL,
  `haproxy1_https_backend_port` int(8) NOT NULL,
  `haproxy1_log_server_address` char(32) NOT NULL,
  PRIMARY KEY (`haproxy1_id`),
  KEY `fk_haproxy1_1` (`component_instance_id`),
  CONSTRAINT `fk_haproxy1_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
