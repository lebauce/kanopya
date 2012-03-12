USE `kanopya`;

SET foreign_key_checks=0;
--
-- Table structure for table `keepalived1`
--

CREATE TABLE `keepalived1` (
  `keepalived_id` int(8) unsigned NOT NULL,
  `daemon_method` enum('master','backup','both') NOT NULL DEFAULT 'master',
  `iface` char(64) DEFAULT NULL,
  `notification_email` char(255) DEFAULT 'admin@hedera-technology.com',
  `notification_email_from` char(255) DEFAULT 'keepalived@some-cluster.com',
  `smtp_server` char(39) NOT NULL,
  `smtp_connect_timeout` int(2) unsigned NOT NULL DEFAULT 30,
  `lvs_id` char(32) NOT NULL DEFAULT 'MAIN_LVS',
  PRIMARY KEY (`keepalived_id`),
  CONSTRAINT `fk_keepalived1_1` FOREIGN KEY (`keepalived_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION

) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `keepalived1_virtualserver`
--

CREATE TABLE `keepalived1_virtualserver` (
  `virtualserver_id` int(8) unsigned NOT NULL AUTO_INCREMENT, 
  `keepalived_id` int(8) unsigned NOT NULL,
  `virtualserver_ip` char(39) NOT NULL,
  `virtualserver_port` int(2) unsigned NOT NULL,
  `virtualserver_lbalgo` enum('rr','wrr','lc','wlc','sh','dh','lblc') NOT NULL DEFAULT 'rr',
  `virtualserver_lbkind` enum('NAT','DR','TUN') NOT NULL DEFAULT 'NAT',
  PRIMARY KEY (`virtualserver_id`),
  KEY `fk_keepalived1_virtualserver_1` (`keepalived_id`),
  CONSTRAINT `fk_keepalived1_virtualserver_1` FOREIGN KEY (`keepalived_id`) REFERENCES `keepalived1` (`keepalived_id`) ON DELETE CASCADE ON UPDATE NO ACTION

) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `keepalived1_realserver`
--

CREATE TABLE `keepalived1_realserver` (
  `realserver_id` int(8) unsigned NOT NULL AUTO_INCREMENT, 
  `virtualserver_id` int(8) unsigned NOT NULL,
  `realserver_ip` char(39) NOT NULL,
  `realserver_port` int(2) unsigned NOT NULL,
  `realserver_weight` int(2) unsigned NOT NULL,
  `realserver_checkport` int(2) unsigned NOT NULL,
  `realserver_checktimeout` int(2) unsigned NOT NULL,	 
  PRIMARY KEY (`realserver_id`),
  KEY `fk_keepalived1_realserver_1` (`virtualserver_id`),
  CONSTRAINT `fk_keepalived1_realserver_1` FOREIGN KEY (`virtualserver_id`) REFERENCES `keepalived1_virtualserver` (`virtualserver_id`) ON DELETE CASCADE ON UPDATE NO ACTION

) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
