USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for dhcpd3
--

CREATE TABLE `dhcpd3` (
  `dhcpd3_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `component_instance_id` int(8) unsigned NOT NULL,
  `dhcpd3_domain_name` char(128) DEFAULT NULL,
  `dhcpd3_domain_server` char(128) DEFAULT NULL,
  `dhcpd3_servername` char(128) DEFAULT NULL,
  PRIMARY KEY (`dhcpd3_id`),
  KEY `fk_dhcpd3_1` (`component_instance_id`),
  CONSTRAINT `fk_dhcpd3_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for dhcpd3_subnet
--

CREATE TABLE `dhcpd3_subnet` (
  `dhcpd3_subnet_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `dhcpd3_id` int(8) unsigned NOT NULL,
  `dhcpd3_subnet_net` char(40) NOT NULL,
  `dhcpd3_subnet_mask` char(40) NOT NULL,
  PRIMARY KEY (`dhcpd3_subnet_id`),
  KEY `fk_dhcpd3_subnet_1` (`dhcpd3_id`),
  CONSTRAINT `fk_dhcpd3_subnet_1` FOREIGN KEY (`dhcpd3_id`) REFERENCES `dhcpd3` (`dhcpd3_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for dhcpd3_hosts
--

CREATE TABLE `dhcpd3_hosts` (
  `dhcpd3_hosts_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `dhcpd3_subnet_id` int(8) unsigned NOT NULL,
  `dhcpd3_hosts_ipaddr` char(40) NOT NULL,
  `dhcpd3_hosts_mac_address` char(40) NOT NULL,
  `dhcpd3_hosts_hostname` char(40) NOT NULL,
  `kernel_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`dhcpd3_hosts_id`),
  UNIQUE KEY `ukey_dhcp3_host_mac` (`dhcpd3_hosts_mac_address`),
  UNIQUE KEY `ukey_dhcp3_host_ipaddr` (`dhcpd3_hosts_ipaddr`),
  UNIQUE KEY `ukey_dhcp3_hostname` (`dhcpd3_hosts_hostname`),
  KEY `fk_dhcpd3_hosts_1` (`dhcpd3_subnet_id`),
  KEY `fk_dhcpd3_hosts_2` (`kernel_id`),
  CONSTRAINT `fk_dhcpd3_hosts_1` FOREIGN KEY (`dhcpd3_subnet_id`) REFERENCES `dhcpd3_subnet` (`dhcpd3_subnet_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_dhcpd3_hosts_2` FOREIGN KEY (`kernel_id`) REFERENCES `kernel` (`kernel_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;