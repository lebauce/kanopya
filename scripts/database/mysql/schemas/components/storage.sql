USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `linux`
--

CREATE TABLE `storage` (
  `storage_id` int(8) unsigned NOT NULL,  
  PRIMARY KEY (`storage_id`),
  CONSTRAINT FOREIGN KEY (`storage_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
