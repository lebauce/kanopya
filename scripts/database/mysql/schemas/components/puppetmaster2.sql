USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for puppetmaster2
--

CREATE TABLE `puppetmaster2` (
  `puppetmaster2_id` int(8) unsigned NOT NULL,
  `puppetmaster2_options` char(255) DEFAULT NULL,
  PRIMARY KEY (`puppetmaster2_id`),
  FOREIGN KEY (`puppetmaster2_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
