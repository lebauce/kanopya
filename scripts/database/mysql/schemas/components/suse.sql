USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `suse`
--

CREATE TABLE `suse` (
  `suse_id` int(8) unsigned NOT NULL,  
  PRIMARY KEY (`suse_id`),
  CONSTRAINT FOREIGN KEY (`suse_id`) REFERENCES `linux` (`linux_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
