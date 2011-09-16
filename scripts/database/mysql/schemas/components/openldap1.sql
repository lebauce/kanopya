USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `openldap1`
--

CREATE TABLE `openldap1` (
  `openldap1_id` int(8) unsigned NOT NULL AUTO_INCREMENT,  
  `component_instance_id` int(8) unsigned NOT NULL,
  `openldap1_port` int(4) unsigned NOT NULL DEFAULT 389,
  `openldap1_suffix` char(64) NOT NULL DEFAULT 'dc=nodomain',
  `openldap1_directory` char(64) NOT NULL DEFAULT '/var/lib/ldap',
  `openldap1_rootdn` char(64) NOT NULL DEFAULT 'dc=admin,dc=nodomain',
  `openldap1_rootpw` char(64) ,
  
  
  PRIMARY KEY (`openldap1_id`),
  UNIQUE KEY `fk_openldap1_1` (`component_instance_id`),
  CONSTRAINT `fk_openldap1_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
