USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `redhat`
--

CREATE TABLE `redhat` (
  `redhat_id` int(8) unsigned NOT NULL,  
  PRIMARY KEY (`redhat_id`),
  CONSTRAINT FOREIGN KEY (`redhat_id`) REFERENCES `linux` (`linux_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
