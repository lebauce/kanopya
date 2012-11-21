USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `xen`
--

CREATE TABLE `xen` (
  `xen_id` int(8) unsigned NOT NULL  PRIMARY KEY (`kvm_id`),
  `vmm_id` int(8) unsigned NOT NULL,
  CONSTRAINT FOREIGN KEY (`xen_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT FOREIGN KEY (`vmm_id`) REFERENCES `vmm` (`vmm_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;

