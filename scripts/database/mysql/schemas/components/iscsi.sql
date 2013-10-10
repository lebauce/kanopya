USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `linux`
--

CREATE TABLE `iscsi` (
  `iscsi_id` int(8) unsigned NOT NULL,  
  PRIMARY KEY (`iscsi_id`),
  CONSTRAINT FOREIGN KEY (`iscsi_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `iscsi_portal` (
  `iscsi_portal_id` int(8) unsigned NOT NULL AUTO_INCREMENT,  
  `iscsi_id` int(8) unsigned NOT NULL,
  `iscsi_portal_ip` char(15) NOT NULL,
  `iscsi_portal_port` int(8) NOT NULL,
  PRIMARY KEY (`iscsi_portal_id`),
  UNIQUE KEY `iscsi_portal_unique1` (`iscsi_portal_id`, `iscsi_id`, `iscsi_portal_ip`, `iscsi_portal_port`),
  CONSTRAINT FOREIGN KEY (`iscsi_id`) REFERENCES `iscsi` (`iscsi_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
