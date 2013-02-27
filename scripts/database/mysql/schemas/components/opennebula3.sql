USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `opennebula3`
--

CREATE TABLE `opennebula3` (
  `opennebula3_id` int(8) unsigned NOT NULL,
  `install_dir` char(255) NOT NULL DEFAULT '/srv/cloud/one',
  `host_monitoring_interval` int unsigned NOT NULL DEFAULT 600,
  `vm_polling_interval` int unsigned NOT NULL DEFAULT 600,
  `vm_dir` char(255) NOT NULL DEFAULT '/srv/cloud/one/var',
  `scripts_remote_dir` char(255) NOT NULL DEFAULT '/var/tmp/one',
  `image_repository_path` char(255) NOT NULL DEFAULT '/srv/cloud/images',
  `port` int unsigned NOT NULL DEFAULT 2633,
  `hypervisor` char(255) NOT NULL DEFAULT 'xen',
  `debug_level` enum('0','1','2','3') NOT NULL DEFAULT '3',
  `overcommitment_cpu_factor` double unsigned NOT NULL DEFAULT '1',
  `overcommitment_memory_factor` double unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`opennebula3_id`),
  CONSTRAINT FOREIGN KEY (`opennebula3_id`) REFERENCES `virtualization` (`virtualization_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `opennebula3_hypervisor`
--

CREATE TABLE `opennebula3_hypervisor` (
  `opennebula3_hypervisor_id` int(8) unsigned NOT NULL,
  `opennebula3_id` int(8) unsigned NOT NULL,
  `onehost_id` int(8) unsigned NULL DEFAULT NULL,
  PRIMARY KEY (`opennebula3_hypervisor_id`),
  FOREIGN KEY (`opennebula3_hypervisor_id`) REFERENCES `hypervisor` (`hypervisor_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`opennebula3_id`),
  FOREIGN KEY (`opennebula3_id`) REFERENCES `opennebula3` (`opennebula3_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `opennebula3_xen_hypervisor`
--

CREATE TABLE `opennebula3_xen_hypervisor` (
  `opennebula3_xen_hypervisor_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`opennebula3_xen_hypervisor_id`),
  FOREIGN KEY (`opennebula3_xen_hypervisor_id`) REFERENCES `opennebula3_hypervisor` (`opennebula3_hypervisor_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `opennebula3_kvm_hypervisor`
--

CREATE TABLE `opennebula3_kvm_hypervisor` (
  `opennebula3_kvm_hypervisor_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`opennebula3_kvm_hypervisor_id`),
  FOREIGN KEY (`opennebula3_kvm_hypervisor_id`) REFERENCES `opennebula3_hypervisor` (`opennebula3_hypervisor_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `opennebula3_vm`
--

CREATE TABLE `opennebula3_vm` (
  `opennebula3_vm_id` int(8) unsigned NOT NULL,
  `opennebula3_id` int(8) unsigned NOT NULL,
  `onevm_id` int(8) unsigned NULL DEFAULT NULL,
  PRIMARY KEY (`opennebula3_vm_id`),
  FOREIGN KEY (`opennebula3_vm_id`) REFERENCES `virtual_machine` (`virtual_machine_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`opennebula3_id`),
  FOREIGN KEY (`opennebula3_id`) REFERENCES `opennebula3` (`opennebula3_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `opennebula3_repository`
--

CREATE TABLE `opennebula3_repository` (
  `opennebula3_repository_id` int(8) unsigned NOT NULL,
  `datastore_id` int(8) unsigned NULL DEFAULT NULL,
  PRIMARY KEY `fk_opennabula3repository_1` (`opennebula3_repository_id`),
  CONSTRAINT `fk_opennebula3repository_1` FOREIGN KEY (`opennebula3_repository_id`) REFERENCES `repository` (`repository_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `opennebula3_kvm_vm`
--

CREATE TABLE `opennebula3_kvm_vm` (
  `opennebula3_kvm_vm_id` int(8) unsigned NOT NULL,
  `opennebula3_kvm_vm_cores` int(8) unsigned NOT NULL,
  PRIMARY KEY (`opennebula3_kvm_vm_id`),
  FOREIGN KEY (`opennebula3_kvm_vm_id`) REFERENCES `opennebula3_vm` (`opennebula3_vm_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;

