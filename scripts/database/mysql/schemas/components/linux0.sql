USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `linux0`
--

CREATE TABLE `linux0` (
  `linux0_id` int(8) unsigned NOT NULL,  
  PRIMARY KEY (`linux0_id`),
  CONSTRAINT FOREIGN KEY (`linux0_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `linux0_mount` (
  `linux0_mount_id` int(8) unsigned NOT NULL AUTO_INCREMENT,  
  `linux0_id` int(8) unsigned NOT NULL,  
  `linux0_mount_device` char(64) NOT NULL,
  `linux0_mount_point` char(64) NOT NULL,
  `linux0_mount_filesystem` char(32) NOT NULL,
  `linux0_mount_options` char(128) NOT NULL DEFAULT 'defaults',
  `linux0_mount_dumpfreq` int(1) NOT NULL DEFAULT 0,
  `linux0_mount_passnum` enum('0','1','2') NOT NULL DEFAULT 0, 
  PRIMARY KEY (`linux0_mount_id`),
  UNIQUE KEY `linux0_mount_unique1` (`linux0_mount_id`,`linux0_mount_device`,`linux0_mount_point`),
  CONSTRAINT FOREIGN KEY (`linux0_id`) REFERENCES `linux0` (`linux0_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
