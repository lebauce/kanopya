USE `kanopya`;

SET foreign_key_checks=0;

CREATE TABLE `ceph` (
  `ceph_id` int(8) unsigned NOT NULL,
  `ceph_fsid` char(64) NULL,
  PRIMARY KEY (`ceph_id`),
  CONSTRAINT FOREIGN KEY (`ceph_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `ceph_mon` (
  `ceph_mon_id` int(8) unsigned NOT NULL,
  `ceph_mon_secret` char(64) NULL,
  `ceph_id` int(8) unsigned NULL,
  PRIMARY KEY (`ceph_mon_id`),
  CONSTRAINT FOREIGN KEY (`ceph_mon_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (`ceph_id`) REFERENCES `ceph` (`ceph_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `ceph_osd` (
  `ceph_osd_id` int(8) unsigned NOT NULL,
  `ceph_id` int(8) unsigned NULL,
  PRIMARY KEY (`ceph_osd_id`),
  CONSTRAINT FOREIGN KEY (`ceph_osd_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (`ceph_id`) REFERENCES `ceph` (`ceph_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
