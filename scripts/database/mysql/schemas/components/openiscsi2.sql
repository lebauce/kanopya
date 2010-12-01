USE `administrator`;

SET foreign_key_checks=0;
--
-- Table structure for table `openiscsi2`
--

CREATE TABLE `openiscsi2` (
  `openiscsi2_id` int(8) NOT NULL AUTO_INCREMENT,
  `component_instance_id` int(8) unsigned NOT NULL,
  `openiscsi2_target` char(64) NOT NULL,
  `openiscsi2_server` char(32) NOT NULL,
  `openiscsi2_port` int(4) DEFAULT NULL,
  `openiscsi2_mount_point` char(64) DEFAULT NULL,
  `openiscsi2_mount_options` char(64) DEFAULT NULL,
  `openiscsi2_filesystem` char(32) DEFAULT NULL,
  PRIMARY KEY (`openiscsi2_id`),
  KEY `fk_openiscsi2_1` (`component_instance_id`),
  CONSTRAINT `fk_opensicsi2_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
