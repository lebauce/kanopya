USE `kanopya`;

SET foreign_key_checks=0;
--
-- Table structure for table `keepalived1`
--

CREATE TABLE `keepalived1` (
  `keepalived_id` int(8) unsigned NOT NULL,
  `notification_email` char(255) NOT NULL DEFAULT 'admin@hedera-technology.com',
  `smtp_server` char(39) NOT NULL,
  PRIMARY KEY (`keepalived_id`),
  CONSTRAINT `fk_keepalived1_1` FOREIGN KEY (`keepalived_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION

) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `keepalived1_vrrpinstance`
--

CREATE TABLE `keepalived1_vrrpinstance` (
  `vrrpinstance_id` int(8) unsigned NOT NULL AUTO_INCREMENT, 
  `keepalived_id` int(8) unsigned NOT NULL,
  `vrrpinstance_name` char(32) NOT NULL,
  `vrrpinstance_password` char(32) NOT NULL,
  `interface_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`vrrpinstance_id`),
  CONSTRAINT `fk_vrrpinstance_1` FOREIGN KEY (`keepalived_id`) REFERENCES `keepalived1` (`keepalived_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_vrrpinstance_2` FOREIGN KEY (`interface_id`) REFERENCES `interface` (`interface_id`) ON DELETE CASCADE ON UPDATE NO ACTION

) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `keepalived1_virtualip`
--

CREATE TABLE `keepalived1_virtualip` (
  `virtualip_id` int(8) unsigned NOT NULL AUTO_INCREMENT, 
  `vrrpinstance_id` int(8) unsigned NOT NULL,
  `ip_id` int(8) unsigned NOT NULL,
  `interface_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`virtualip_id`),
  CONSTRAINT `fk_virtualip_1` FOREIGN KEY (`vrrpinstance_id`) REFERENCES `keepalived1_vrrpinstance` (`vrrpinstance_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_virtualip_2` FOREIGN KEY (`ip_id`) REFERENCES `ip` (`ip_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_virtualip_3` FOREIGN KEY (`interface_id`) REFERENCES `interface` (`interface_id`) ON DELETE CASCADE ON UPDATE NO ACTION

) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
