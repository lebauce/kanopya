USE `kanopya`;

SET foreign_key_checks=0;

CREATE TABLE `swift_storage` (
  `swift_storage_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`swift_storage_id`),
  CONSTRAINT FOREIGN KEY (`swift_storage_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  `keystone_id` int(8) unsigned NULL DEFAULT NULL,
  FOREIGN KEY (`keystone_id`) REFERENCES `keystone` (`keystone_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `swift_proxy` (
  `swift_proxy_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`swift_proxy_id`),
  CONSTRAINT FOREIGN KEY (`swift_proxy_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  `keystone_id` int(8) unsigned NULL DEFAULT NULL,
  FOREIGN KEY (`keystone_id`) REFERENCES `keystone` (`keystone_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
