USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for puppetagent2
--

CREATE TABLE `puppetagent2` (
  `puppetagent2_id` int(8) unsigned NOT NULL,
  `puppetagent2_options` char(255) DEFAULT NULL,
  `puppetagent2_mode` enum('kanopya','custom') NOT NULL DEFAULT 'kanopya',
  `puppetagent2_masterip` char(15) NOT NULL,
  `puppetagent2_masterfqdn` char(255) NOT NULL,
  PRIMARY KEY (`puppetagent2_id`),
  FOREIGN KEY (`puppetagent2_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
