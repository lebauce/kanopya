USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `haproxy1`
--

CREATE TABLE `haproxy1` (
  `haproxy1_id` int(8) unsigned NOT NULL,
  `haproxy1_http_frontend_port` int(8) NOT NULL,
  `haproxy1_http_backend_port` int(8) NOT NULL,
  `haproxy1_https_frontend_port` int(8) NOT NULL,
  `haproxy1_https_backend_port` int(8) NOT NULL,
  `haproxy1_log_server_address` char(32) NOT NULL,
  PRIMARY KEY (`haproxy1_id`),
  CONSTRAINT `fk_haproxy1_1` FOREIGN KEY (`haproxy1_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
