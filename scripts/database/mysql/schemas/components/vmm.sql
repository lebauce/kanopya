USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `kvm`
--

CREATE TABLE `vmm` (
  `vmm_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`vmm_id`),
  `iaas_id` int(8) unsigned NOT NULL,
  CONSTRAINT FOREIGN KEY (`vmm_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT FOREIGN KEY (`iaas_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;

