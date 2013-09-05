USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for tftpd
--

CREATE TABLE `tftpd` (
  `tftpd_id` int(8) unsigned NOT NULL,
  `tftpd_repository` char(64) DEFAULT NULL,
  PRIMARY KEY (`tftpd_id`),
  CONSTRAINT `fk_tftpd_1` FOREIGN KEY (`tftpd_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
