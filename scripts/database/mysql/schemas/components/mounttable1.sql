USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `mounttable1`
--

CREATE TABLE `mounttable1` (
  `mounttable1_id` int(8) unsigned NOT NULL AUTO_INCREMENT,  
  `component_instance_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`mounttable1_id`),
  KEY `fk_mounttable1_1` (`component_instance_id`),
  CONSTRAINT `fk_mounttable1_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
