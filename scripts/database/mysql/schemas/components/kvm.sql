USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `kvm`
--

CREATE TABLE `kvm` (
  `kvm_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`kvm_id`),
  CONSTRAINT FOREIGN KEY (`kvm_id`) REFERENCES `vmm` (`vmm_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
