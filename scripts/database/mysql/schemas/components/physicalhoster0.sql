USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `physicalhoster0`
--

CREATE TABLE `physicalhoster0` (
  `physicalhoster0_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`physicalhoster0_id`),
  CONSTRAINT FOREIGN KEY (`physicalhoster0_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
