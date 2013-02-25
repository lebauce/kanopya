USE `kanopya`

SET foreign_key_checks=0;

--
-- Table structure for table `glance`
--

CREATE TABLE `glance` (
  `glance_id` int(8) unsigned NOT NULL,
  `mysql5_id` int(8) unsigned NULL DEFAULT NULL,
  `nova_controller_id` int(8) unsigned NULL DEFAULT NULL,
  PRIMARY KEY (`glance_id`),
  CONSTRAINT `fk_glance_1` FOREIGN KEY (`glance_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY(`mysql5_id`),
  FOREIGN KEY (`mysql5_id`) REFERENCES `mysql5` (`mysql5_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY(`nova_controller_id`),
  FOREIGN KEY (`nova_controller_id`) REFERENCES `nova_controller` (`nova_controller_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `keystone`
--

CREATE TABLE `keystone` (
  `keystone_id` int(8) unsigned NOT NULL,
  `mysql5_id` int(8) unsigned NULL DEFAULT NULL,
  PRIMARY KEY (`keystone_id`),
  CONSTRAINT `fk_keystone_1` FOREIGN KEY (`keystone_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY(`mysql5_id`),
  FOREIGN KEY (`mysql5_id`) REFERENCES `mysql5` (`mysql5_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `nova_compute`
--

CREATE TABLE `nova_compute` (
  `nova_compute_id` int(8) unsigned NOT NULL,
  `mysql5_id` int(8) unsigned NULL DEFAULT NULL,
  `nova_controller_id` int(8) unsigned NULL DEFAULT NULL,
  PRIMARY KEY (`nova_compute_id`),
  CONSTRAINT `fk_nova_compute_1` FOREIGN KEY (`nova_compute_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY(`mysql5_id`),
  FOREIGN KEY (`mysql5_id`) REFERENCES `mysql5` (`mysql5_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY(`nova_controller_id`),
  FOREIGN KEY (`nova_controller_id`) REFERENCES `nova_controller` (`nova_controller_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `nova_controller`
--

CREATE TABLE `nova_controller` (
  `nova_controller_id` int(8) unsigned NOT NULL,
  `mysql5_id` int(8) unsigned NULL DEFAULT NULL,
  `amqp_id` int(8) unsigned NULL DEFAULT NULL,
  `keystone_id` int(8) unsigned NULL DEFAULT NULL,
  PRIMARY KEY (`nova_controller_id`),
  CONSTRAINT `fk_nova_controller_1` FOREIGN KEY (`nova_controller_id`) REFERENCES `virtualization` (`virtualization_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY(`mysql5_id`),
  FOREIGN KEY (`mysql5_id`) REFERENCES `mysql5` (`mysql5_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY(`amqp_id`),
  FOREIGN KEY (`amqp_id`) REFERENCES `amqp` (`amqp_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY(`keystone_id`),
  FOREIGN KEY (`keystone_id`) REFERENCES `keystone` (`keystone_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `quantum`
--

CREATE TABLE `quantum` (
  `quantum_id` int(8) unsigned NOT NULL,
  `mysql5_id` int(8) unsigned NULL DEFAULT NULL,
  `nova_controller_id` int(8) unsigned NULL DEFAULT NULL,
  PRIMARY KEY (`quantum_id`),
  CONSTRAINT `fk_quantum_1` FOREIGN KEY (`quantum_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY(`mysql5_id`),
  FOREIGN KEY (`mysql5_id`) REFERENCES `mysql5` (`mysql5_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY(`nova_controller_id`),
  FOREIGN KEY (`nova_controller_id`) REFERENCES `nova_controller` (`nova_controller_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `openstack_hypervisor`
--

CREATE TABLE `openstack_hypervisor` (
  `openstack_hypervisor_id` int(8) unsigned NOT NULL,
  `nova_controller_id` int(8) unsigned NOT NULL,
  `openstack_hypervisor_uuid` int(8) unsigned NULL DEFAULT NULL,
  PRIMARY KEY (`openstack_hypervisor_id`),
  FOREIGN KEY (`openstack_hypervisor_id`) REFERENCES `hypervisor` (`hypervisor_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`nova_controller_id`),
  FOREIGN KEY (`nova_controller_id`) REFERENCES `nova_controller` (`nova_controller_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `openstack_vm`
--

CREATE TABLE `openstack_vm` (
  `openstack_vm_id` int(8) unsigned NOT NULL,
  `nova_controller_id` int(8) unsigned NOT NULL,
  `openstack_vm_uuid` char(64) NULL DEFAULT NULL,
  PRIMARY KEY (`openstack_vm_id`),
  FOREIGN KEY (`openstack_vm_id`) REFERENCES `virtual_machine` (`virtual_machine_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (`nova_controller_id`) REFERENCES `nova_controller` (`nova_controller_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `openstack_repository`
--

CREATE TABLE `openstack_repository` (
  `openstack_repository_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `nova_controller_id` int(8) unsigned NOT NULL,
  `repository_name` char(255) NOT NULL,
  `container_access_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`openstack_repository_id`),
  FOREIGN KEY (`nova_controller_id`) REFERENCES `nova_controller` (`nova_controller_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (`container_access_id`) REFERENCES `container_access` (`container_access_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;

