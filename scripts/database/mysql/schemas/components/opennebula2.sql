USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `opennebula2`
--

CREATE TABLE `opennebula2` (
  `opennebula2_id` int(8) unsigned NOT NULL AUTO_INCREMENT,  
  `component_instance_id` int(8) unsigned NOT NULL,
  `host_monitoring_interval` int unsigned NOT NULL DEFAULT 600,
  `vm_polling_interval` int unsigned NOT NULL DEFAULT 600,
  `vm_dir` char(255) NOT NULL DEFAULT '/srv/cld/one/var',
  `scripts_remote_dir` char(255) NOT NULL DEFAULT '/var/tmp/one',
  `image_repository_path` char(255) NOT NULL DEFAULT '/srv/cloud/images',
  `port` int unsigned NOT NULL DEFAULT 2633,
  `debug_level` enum('0','1','2','3') NOT NULL DEFAULT '3', 	
  PRIMARY KEY (`opennebula2_id`),
  KEY `fk_opennebula2_1` (`component_instance_id`),
  CONSTRAINT `fk_opennebula2_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
