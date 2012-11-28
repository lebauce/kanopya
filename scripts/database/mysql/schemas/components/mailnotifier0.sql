USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `mailnotifier0`
--

CREATE TABLE `mailnotifier0` (
  `mailnotifier0_id` int(8) unsigned NOT NULL,
  `smtp_server` char(255) default 'localhost',
  `smtp_login` char(32) DEFAULT NULL,
  `smtp_passwd` char(32) DEFAULT NULL,
  `use_ssl` int(1) unsigned default 0,
  PRIMARY KEY (`mailnotifier0_id`),
  CONSTRAINT FOREIGN KEY (`mailnotifier0_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
