USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `memcached1`
--

CREATE TABLE `memcached1` (
  `memcached1_id` int(8) unsigned NOT NULL,
  `memcached1_port` int(8) unsigned NOT NULL,
  PRIMARY KEY (`memcached1_id`),
  CONSTRAINT `fk_memcached1_1` FOREIGN KEY (`memcached1_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
