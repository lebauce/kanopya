USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `iscsitarget1`
--

CREATE TABLE `iscsitarget1` (
  `iscsitarget1_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`iscsitarget1_id`),
  CONSTRAINT FOREIGN KEY (`iscsitarget1_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `iscsitarget1_target`
--

CREATE TABLE `iscsitarget1_target` (
  `iscsitarget1_target_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `iscsitarget1_id` int(8) unsigned NOT NULL,
  `iscsitarget1_target_name` char(128) NOT NULL,
  PRIMARY KEY (`iscsitarget1_target_id`),
  UNIQUE KEY `iscsitarget1_UNIQUE` (`iscsitarget1_target_name`),
  KEY `fk_iscsitarget1_1` (`iscsitarget1_id`),
  CONSTRAINT `fk_iscsitarget1_1` FOREIGN KEY (`iscsitarget1_id`) REFERENCES `iscsitarget1` (`iscsitarget1_id`) ON DELETE CASCADE ON UPDATE NO ACTION

) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `iscsitarget1_lun`
--

CREATE TABLE `iscsitarget1_lun` (
  `iscsitarget1_lun_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `iscsitarget1_target_id` int(8) unsigned NOT NULL,
  `iscsitarget1_lun_number` int(8) unsigned NOT NULL,
  `iscsitarget1_lun_device` char(64) NOT NULL,
  `iscsitarget1_lun_typeio` char(32) NOT NULL,
  `iscsitarget1_lun_iomode` char(16) NOT NULL,
  PRIMARY KEY (`iscsitarget1_lun_id`),
  KEY `fk_iscsitarget1_lun_1` (`iscsitarget1_target_id`),
  CONSTRAINT `fk_iscsitarget1_lun_1` FOREIGN KEY (`iscsitarget1_target_id`) REFERENCES `iscsitarget1_target` (`iscsitarget1_target_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
