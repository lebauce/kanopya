USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `debian`
--

CREATE TABLE `debian` (
  `debian_id` int(8) unsigned NOT NULL,  
  PRIMARY KEY (`debian_id`),
  CONSTRAINT FOREIGN KEY (`debian_id`) REFERENCES `linux` (`linux_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
