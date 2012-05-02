USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for puppetagent2
--

CREATE TABLE `puppetagent2` (
  `puppetagent2_id` int(8) unsigned NOT NULL,
  `puppetagent2_bootstart` enum('no','yes') NULL DEFAULT 'no',
  `puppetagent2_options` char(255) DEFAULT NULL,
  `puppetagent2_masterserver` char(255) DEFAULT NULL,
  PRIMARY KEY (`puppetagent2_id`),
  FOREIGN KEY (`puppetagent2_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
