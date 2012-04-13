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

SET foreign_key_checks=1;

