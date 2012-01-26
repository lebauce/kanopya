USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `mounttable1`
--

CREATE TABLE `mounttable1` (
  `mounttable1_id` int(8) unsigned NOT NULL,
  `mounttable1_device` char(64) NOT NULL,
  `mounttable1_mountpoint` char(64) NOT NULL,
  `mounttable1_filesystem` char(32) NOT NULL,
  `mounttable1_options` char(128) NOT NULL DEFAULT 'defaults',
  `mounttable1_dumpfreq` int(1) NOT NULL DEFAULT 0,
  `mounttable1_passnum` enum('0','1','2') NOT NULL DEFAULT 0, 
  PRIMARY KEY (`mounttable1_id`),
  UNIQUE KEY `mounttable1_unique1` (`mounttable1_id`,`mounttable1_device`,`mounttable1_mountpoint`),
  KEY `fk_mounttable1_1` (`component_id`),
  CONSTRAINT `fk_mounttable1_1` FOREIGN KEY (`component_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
