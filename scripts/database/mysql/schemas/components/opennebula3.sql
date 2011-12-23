USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `opennebula3`
--

CREATE TABLE `opennebula3` (
  `opennebula3_id` int(8) unsigned NOT NULL AUTO_INCREMENT,  
  `component_instance_id` int(8) unsigned NOT NULL,
  `install_dir` char(255) NOT NULL DEFAULT '/srv/cloud/one',
  `host_monitoring_interval` int unsigned NOT NULL DEFAULT 600,
  `vm_polling_interval` int unsigned NOT NULL DEFAULT 600,
  `vm_dir` char(255) NOT NULL DEFAULT '/srv/cloud/one/var',
  `scripts_remote_dir` char(255) NOT NULL DEFAULT '/var/tmp/one',
  `image_repository_path` char(255) NOT NULL DEFAULT '/srv/cloud/images',
  `port` int unsigned NOT NULL DEFAULT 2633,
  `debug_level` enum('0','1','2','3') NOT NULL DEFAULT '3', 	
  PRIMARY KEY (`opennebula3_id`),
  KEY `fk_opennebula3_1` (`component_instance_id`),
  CONSTRAINT `fk_opennebula3_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `opennebula3_hypervisor`
--

CREATE TABLE `opennebula3_hypervisor` (
  `opennebula3_hypervisor_id` int(8) unsigned NOT NULL AUTO_INCREMENT, 
  `opennebula3_id` int(8) unsigned NOT NULL,  
  `hypervisor_host_id` int(8) unsigned NOT NULL,
  `hypervisor_id` int(8) unsigned NULL DEFAULT NULL,
  PRIMARY KEY (`opennebula3_hypervisor_id`),
  KEY `fk_opennebula3hyperisor_1` (`opennebula3_id`),
  KEY `fk_opennebula3hyperisor_2` (`hypervisor_host_id`),
  CONSTRAINT `fk_opennebula3hyperisor_1` FOREIGN KEY (`opennebula3_id`) REFERENCES `opennebula3` (`opennebula3_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_opennebula3hyperisor_2` FOREIGN KEY (`hypervisor_host_id`) REFERENCES `host` (`host_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `opennebula3_vm`
--

CREATE TABLE `opennebula3_vm` (
  `opennebula3_vm_id` int(8) unsigned NOT NULL AUTO_INCREMENT, 
  `opennebula3_id` int(8) unsigned NOT NULL,  
  `vm_host_id` int(8) unsigned NOT NULL,
  `hypervisor_id` int(8) unsigned NULL DEFAULT NULL,  
  `vm_id` int(8) unsigned NULL DEFAULT NULL,  
  `vnc_port` int(8) unsigned NULL DEFAULT NULL,
  PRIMARY KEY (`opennebula3_vm_id	`),
  KEY `fk_opennebula3vm_1` (`opennebula3_id`),
  CONSTRAINT `fk_opennebula3vm_1` FOREIGN KEY (`opennebula3_id`) REFERENCES `opennebula3` (`opennebula3_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY `fk_opennebula3vm_2` (`vm_host_id`),
  CONSTRAINT `fk_opennebula3vm_2` FOREIGN KEY (`vm_host_id`) REFERENCES `host` (`host_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY `fk_opennebula3vm_3` (`hypervisor_id`),
  CONSTRAINT `fk_opennebula3vm_3` FOREIGN KEY (`hypervisor_id`) REFERENCES `opennebula3_hypervisor` (`hypervisor_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;

