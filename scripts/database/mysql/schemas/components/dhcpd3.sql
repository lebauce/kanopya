USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for dhcpd3
--

CREATE TABLE `dhcpd3` (
  `dhcpd3_id` int(8) unsigned NOT NULL,
  `dhcpd3_domain_name` char(128) DEFAULT NULL,
  `dhcpd3_domain_server` char(128) DEFAULT NULL,
  `dhcpd3_servername` char(128) DEFAULT NULL,
  PRIMARY KEY (`dhcpd3_id`),
  CONSTRAINT FOREIGN KEY (`dhcpd3_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for dhcpd3_subnet
--

CREATE TABLE `dhcpd3_subnet` (
  `dhcpd3_subnet_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `dhcpd3_id` int(8) unsigned NOT NULL,
  `network_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`dhcpd3_subnet_id`),
  KEY `fk_dhcpd3_subnet_1` (`dhcpd3_id`),
  KEY `fk_dhcpd3_subnet_2` (`network_id`),
  CONSTRAINT `fk_dhcpd3_subnet_1` FOREIGN KEY (`dhcpd3_id`) REFERENCES `dhcpd3` (`dhcpd3_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_dhcpd3_subnet_2` FOREIGN KEY (`network_id`) REFERENCES `network` (`network_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `dhcpd3_hosts` (
  `dhcpd3_hosts_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `dhcpd3_hosts_pxe` int(2) DEFAULT 0,
  `dhcpd3_subnet_id` int(8) unsigned NOT NULL,
  `iface_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`dhcpd3_hosts_id`),
  KEY `fk_dhcpd3_hosts_1` (`dhcpd3_subnet_id`),
  KEY `fk_dhcpd3_hosts_2` (`iface_id`),
  CONSTRAINT `fk_dhcpd3_hosts_1` FOREIGN KEY (`dhcpd3_subnet_id`) REFERENCES `dhcpd3_subnet` (`dhcpd3_subnet_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_dhcpd3_hosts_2` FOREIGN KEY (`iface_id`) REFERENCES `iface` (`iface_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
