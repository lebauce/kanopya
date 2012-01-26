USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `openiscsi2`
--

CREATE TABLE `openiscsi2` (
  `openiscsi2_id` int(8) NOT NULL,
  PRIMARY KEY (`openiscsi2_id`),
  CONSTRAINT FOREIGN KEY (`openiscsi2_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `openiscsi2_target` (
  `openiscsi2_target_id` int(8) NOT NULL AUTO_INCREMENT,
  `openiscsi2_id` int(8) NOT NULL,
  `openiscsi2_target` char(64) NOT NULL,
  `openiscsi2_server` char(32) NOT NULL,
  `openiscsi2_port` int(4) DEFAULT NULL,
  `openiscsi2_mount_point` char(64) DEFAULT NULL,
  `openiscsi2_mount_options` char(64) DEFAULT NULL,
  `openiscsi2_filesystem` char(32) DEFAULT NULL,
  PRIMARY KEY (`openiscsi2_target_id`),
  KEY `fk_openiscsi2_target1` (`component_instance_id`),
  CONSTRAINT `fk_opensicsi2_target1` FOREIGN KEY (`openiscsi2_id`) REFERENCES `openiscsi2` (`openiscsi2_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


SET foreign_key_checks=1;
