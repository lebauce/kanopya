USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for nfsd3
--

CREATE TABLE `nfsd3` (
  `nfsd3_id` int(8) unsigned NOT NULL,
  `nfsd3_statdopts` char(128) NULL,
  `nfsd3_need_gssd` enum('yes','no') NOT NULL DEFAULT 'no',
  `nfsd3_rpcnfsdcount` int(1) unsigned NOT NULL DEFAULT 8,
  `nfsd3_rpcnfsdpriority` int(1) NOT NULL DEFAULT 0,
  `nfsd3_rpcmountopts` char(255) NULL,
  `nfsd3_need_svcgssd` enum('yes','no') NOT NULL DEFAULT 'no',
  `nfsd3_rpcsvcgssdopts` char(255) NULL,
  PRIMARY KEY (`nfsd3_id`),
  CONSTRAINT FOREIGN KEY (`nfsd3_id`) REFERENCES `component` (`component_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for nfsd3_export
--

CREATE TABLE `nfsd3_export` (
  `nfsd3_export_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `nfsd3_id` int(8) unsigned NOT NULL,
  `nfsd3_export_path` char(255) NOT NULL,
  PRIMARY KEY (`nfsd3_export_id`),
  KEY `fk_nfsd3_export_1` (`nfsd3_id`),
  CONSTRAINT `fk_nfsd3_export_1` FOREIGN KEY (`nfsd3_id`) REFERENCES `nfsd3` (`nfsd3_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for nfsd3_exportclient
--

CREATE TABLE `nfsd3_exportclient` (
  `nfsd3_exportclient_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `nfsd3_export_id` int(8) unsigned NOT NULL,
  `nfsd3_exportclient_name` char(255) NOT NULL,
  `nfsd3_exportclient_options` char(255) NOT NULL,
  PRIMARY KEY (`nfsd3_exportclient_id`),
  KEY `fk_nfsd3_exportclient_1` (`nfsd3_export_id`),
  CONSTRAINT `fk_nfsd3_exportclient_1` FOREIGN KEY (`nfsd3_export_id`) REFERENCES `nfsd3_export` (`nfsd3_export_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;

