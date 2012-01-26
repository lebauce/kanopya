USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `mounttable1`
--

CREATE TABLE `mounttable1` (
  `mounttable1_id` int(8) unsigned NOT NULL,  
  PRIMARY KEY (`mounttable1_id`),
  CONSTRAINT FOREIGN KEY (`mounttable1_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `mounttable1_mount` (
  `mounttable1_mount_id` int(8) unsigned NOT NULL AUTO_INCREMENT,  
  `mounttable1_id` int(8) unsigned NOT NULL,  
  `mounttable1_mount_device` char(64) NOT NULL,
  `mounttable1_mount_point` char(64) NOT NULL,
  `mounttable1_mount_filesystem` char(32) NOT NULL,
  `mounttable1_mount_options` char(128) NOT NULL DEFAULT 'defaults',
  `mounttable1_mount_dumpfreq` int(1) NOT NULL DEFAULT 0,
  `mounttable1_mount_passnum` enum('0','1','2') NOT NULL DEFAULT 0, 
  PRIMARY KEY (`mounttable1_mount_id`),
  UNIQUE KEY `mounttable1_mount_unique1` (`mounttable1_mount_id`,`mounttable1_mount_device`,`mounttable1_mount_point`),
  CONSTRAINT FOREIGN KEY (`mounttable1_id`) REFERENCES `mounttable1` (`mounttable1_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
