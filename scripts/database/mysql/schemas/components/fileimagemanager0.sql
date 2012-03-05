USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `fileimagemanager0`
--

CREATE TABLE `fileimagemanager0` (
  `fileimagemanager0_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`fileimagemanager0_id`),
  CONSTRAINT FOREIGN KEY (`fileimagemanager0_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
