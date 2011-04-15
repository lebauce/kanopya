USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `Pleskpanel10`
--

CREATE TABLE `Pleskpanel10` (
  `component_instance_id` int(8) unsigned NOT NULL,
  `pleskpanel10_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `pleskpanel10_hostname` char(32) NOT NULL DEFAULT 'hostname',
  PRIMARY KEY (`pleskpanel10_id`),
  KEY `fk_pleskpanel10_1` (`component_instance_id`),
  CONSTRAINT `fk_pleskpanel10_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
