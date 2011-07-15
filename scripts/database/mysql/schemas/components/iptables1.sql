USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `iptables1_`
--
CREATE TABLE `iptables1_sec_rule` (
  `iptables1_sec_rule_id` int(3) unsigned NOT NULL AUTO_INCREMENT,
  `component_instance_id` int(8) unsigned NOT NULL,
  `iptables1_sec_rule_syn_flood`  int(1) unsigned NOT NULL,
  `iptables1_sec_rule_scan_furtif` int(1) unsigned NOT NULL,
  `iptables1_sec_rule_ping_mort` int(1) unsigned NOT NULL,
  `iptables1_sec_rule_anti_spoofing` int(1) unsigned NOT NULL,

  PRIMARY KEY (`iptables1_sec_rule_id`),
  UNIQUE KEY `fk_iptables1_sec_rule_1` (`component_instance_id`),
  CONSTRAINT `fk_iptables1_sec_rule_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;




CREATE TABLE `iptables1_component` (
  `iptables1_component_id` int(3) unsigned NOT NULL AUTO_INCREMENT,
  `iptables1_sec_rule_id` int(3) unsigned NOT NULL,
  `component_instance_id` int(8) unsigned NOT NULL,
  `iptables1_component_cible` int(1) unsigned NOT NULL,
   PRIMARY KEY (`iptables1_component_id`),

  KEY `fk_iptables1_component_1` (`iptables1_sec_rule_id`),
  CONSTRAINT `fk_iptables1_component_1` FOREIGN KEY (`iptables1_sec_rule_id`) REFERENCES `iptables1_sec_rule` (`iptables1_sec_rule_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


SET foreign_key_checks=1;





