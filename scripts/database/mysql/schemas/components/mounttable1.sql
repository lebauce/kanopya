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

CREATE TABLE `mount` (
  `mount_id` int(8) unsigned NOT NULL AUTO_INCREMENT,  
  `mounttable1_id` int(8) unsigned NOT NULL,  
  `mount_device` char(64) NOT NULL,
  `mount_mountpoint` char(64) NOT NULL,
  `mount_filesystem` char(32) NOT NULL,
  `mount_options` char(128) NOT NULL DEFAULT 'defaults',
  `mount_dumpfreq` int(1) NOT NULL DEFAULT 0,
  `mount_passnum` enum('0','1','2') NOT NULL DEFAULT 0, 
  PRIMARY KEY (`mount_id`),
  UNIQUE KEY `mount1_unique1` (`mount_id`,`mount_device`,`mount_mountpoint`),
  CONSTRAINT FOREIGN KEY (`mounttable1_id`) REFERENCES `mounttable1` (`mounttable1_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
