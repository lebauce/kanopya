USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `iptables1`
--

CREATE TABLE `iptables1` (
  `iptables1_id` int(3) unsigned NOT NULL AUTO_INCREMENT,
  `component_instance_id` int(8) unsigned NOT NULL,
  `iptables1_tables` char(8) NOT NULL,
  `iptables1_chaine` char(11) NOT NULL,
  `iptables1_protocole` char(8) NOT NULL,
  `iptables1_number_port` int(6) NOT NULL,
  `iptables1_cible` char(8) NOT NULL,
  PRIMARY KEY (`iptables1_id`),
  KEY `fk_iptables1_1` (`component_instance_id`),
  CONSTRAINT `fk_iptables1_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
