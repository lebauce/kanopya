CREATE TABLE `keystone_endpoint` (
  `open_stack_id` int(8) unsigned NOT NULL,
  `keystone_uuid` char(64) NOT NULL,
  PRIMARY KEY (`keystone_uuid`),
  FOREIGN KEY (`open_stack_id`) REFERENCES `open_stack` (`open_stack_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- DOWN --
DROP TABLE IF EXISTS `keystone_endpoint`;
