USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `openssh5`
--

CREATE TABLE `openssh5` (
  `openssh5_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`openssh5_id`),
  CONSTRAINT FOREIGN KEY (`openssh5_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
