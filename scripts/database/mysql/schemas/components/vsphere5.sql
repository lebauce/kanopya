USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `vsphere5`
--

CREATE TABLE `vsphere5` (
    `vsphere5_id` int(8) unsigned NOT NULL,
    `vsphere5_login` char(255),
    `vsphere5_pwd` char(255),
    PRIMARY KEY (`vsphere5_id`),
    CONSTRAINT FOREIGN KEY (`vsphere5_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `vsphere5_hypervisor`
--

CREATE TABLE `vsphere5_hypervisor` (
    `vsphere5_hypervisor_id` int(8) unsigned NOT NULL,
    `vsphere5_id` int(8) unsigned NOT NULL,
    `vsphere5_datacenter_id` int(8) unsigned NOT NULL,
    PRIMARY KEY (`vsphere5_hypervisor_id`),
    FOREIGN KEY (`vsphere5_hypervisor_id`) REFERENCES `hypervisor` (`hypervisor_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
    KEY (`vsphere5_id`),
    FOREIGN KEY (`vsphere5_id`) REFERENCES `vsphere5` (`vsphere5_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
    KEY (`vsphere5_datacenter_id`),
    FOREIGN KEY (`vsphere5_datacenter_id`) REFERENCES `vsphere5_datacenter` (`vsphere5_datacenter_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `vsphere5_vm`
--

CREATE TABLE `vsphere5_vm` (
    `vsphere5_vm_id` int(8) unsigned NOT NULL,
    `vsphere5_id` int(8) unsigned NOT NULL,
    `vsphere5_guest_id` char(128) NOT NULL,
    PRIMARY KEY (`vsphere5_vm_id`),
    FOREIGN KEY (`vsphere5_vm_id`) REFERENCES `virtual_machine` (`virtual_machine_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
    KEY (`vsphere5_id`),
    FOREIGN KEY (`vsphere5_id`) REFERENCES `vsphere5` (`vsphere5_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `vsphere5_repository`
--

CREATE TABLE `vsphere5_repository` (
    `vsphere5_repository_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
    `vsphere5_id` int(8) unsigned NOT NULL,
    `repository_name` char(255) NOT NULL,
    `container_access_id` int(8) unsigned NOT NULL,
    PRIMARY KEY (`vsphere5_repository_id`),
    FOREIGN KEY (`vsphere5_id`) REFERENCES `vsphere5` (`vsphere5_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
    FOREIGN KEY (`container_access_id`) REFERENCES `container_access` (`container_access_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `vsphere5_datacenter`
--

CREATE TABLE `vsphere5_datacenter` (
    `vsphere5_datacenter_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
    `vsphere5_datacenter_name` char(255) NOT NULL,
    `vsphere5_id` int(8) unsigned NOT NULL,
    PRIMARY KEY (`vsphere5_datacenter_id`),
    FOREIGN KEY (`vsphere5_id`) REFERENCES `vsphere5` (`vsphere5_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
