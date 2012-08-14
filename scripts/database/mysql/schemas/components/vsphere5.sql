USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `vsphere5`
--

CREATE TABLE `vsphere5` (
    `vsphere5_id` int(8) unsigned NOT NULL,
    PRIMARY KEY (`vsphere5_id`),
    CONSTRAINT FOREIGN KEY (`vsphere5_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `vsphere5_hypervisor`
--

CREATE TABLE `vsphere5_hypervisor` (
    `vsphere5_hypervisor_id` int(8) unsigned NOT NULL,
    `vsphere5_id` int(8) unsigned NOT NULL,
    PRIMARY KEY (`vsphere5_hypervisor_id`),
    FOREIGN KEY (`vsphere5_hypervisor_id`) REFERENCES `hypervisor` (`hypervisor_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
    KEY (`vsphere5_id`),
    FOREIGN KEY (`vsphere5_id`) REFERENCES `vsphere5` (`vsphere5_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `vsphere5_vm`
--

CREATE TABLE `vsphere5_vm` (
    `vsphere5_vm_id` int(8) unsigned NOT NULL,
    `vsphere5_id` int(8) unsigned NOT NULL,
    PRIMARY KEY (`vsphere5_vm_id`),
    FOREIGN KEY (`vsphere5_vm_id`) REFERENCES `virtual_machine` (`virtual_machine_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
    KEY (`vsphere5_id`),
    FOREIGN KEY (`vsphere5_id`) REFERENCES `vsphere5` (`vsphere5_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;