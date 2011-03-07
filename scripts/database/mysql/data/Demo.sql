USE `administrator`;
SET foreign_key_checks=0;
SET @eid := 1;

--
-- permanents data
--

-- user and groups
INSERT INTO `groups` VALUES 
(1,'User','User master group',1),
(2,'Processortemplate','Processortemplate master group',1),
(3,'Motherboardtemplate','Motherboardtemplate master group',1),
(4,'Motherboard','Motherboard master group',1),
(5,'Cluster','Cluster master group',1),
(6,'Distribution','Distribution master group',1),
(7,'Kernel','Kernel master group',1),
(8,'Systemimage','Systemimage master group',1),
(9,'Operationtype','Operationtype master group',1),
(10,'admin','for administration tasks',1);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,1); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,2); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,3); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,4); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,5); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,6); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,7); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,8); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,9); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,10); SET @eid := @eid +1;


INSERT INTO `user` VALUES (1,'executer','executer','executer','executer',NULL,'2010-07-22',NULL,'executer');
INSERT INTO `entity` VALUES (@eid); INSERT INTO `user_entity` VALUES (@eid,1); SET @eid := @eid +1;

-- processor models
INSERT INTO `processormodel` VALUES (1,'Intel','Atom 330',2,1.6,1,8,1);
INSERT INTO `processormodel` VALUES (2,'Intel','Atom D510',2,1.66,1,13,1);
INSERT INTO `processormodel` VALUES (3,'VIA Nano','L2200',2,1.6,1,13,1);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `processormodel_entity` VALUES (@eid,1); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `processormodel_entity` VALUES (@eid,2); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `processormodel_entity` VALUES (@eid,3); SET @eid := @eid +1;

-- motherboard models
INSERT INTO `motherboardmodel` VALUES (1,'INTEL','DG945GCLF2','945GC',1,42,1,1,2,1);
INSERT INTO `motherboardmodel` VALUES (2,'ASUS','AT3GC-I','945GC',1,42,1,1,2,1);
INSERT INTO `motherboardmodel` VALUES (3,'ASUS','AT3N7A-I','NVIDIA ION',1,40,1,2,4,1);
INSERT INTO `motherboardmodel` VALUES (4,'J&W','MINIX ATOM330','945GC',1,46,1,1,2,1);
INSERT INTO `motherboardmodel` VALUES (5,'VIA','VB8001','VIA CN896',1,17,1,2,4,3);
INSERT INTO `motherboardmodel` VALUES (6,'GIGABYTE','GA-D510UD','INTEL NM10',1,26,1,2,4,2);
INSERT INTO `motherboardmodel` VALUES (7,'INTEL','D510MO','INTEL NM10',1,21,1,2,4,2);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `motherboardmodel_entity` VALUES (@eid,1); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `motherboardmodel_entity` VALUES (@eid,2); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `motherboardmodel_entity` VALUES (@eid,3); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `motherboardmodel_entity` VALUES (@eid,4); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `motherboardmodel_entity` VALUES (@eid,5); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `motherboardmodel_entity` VALUES (@eid,6); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `motherboardmodel_entity` VALUES (@eid,7); SET @eid := @eid +1;


-- operation types list
INSERT INTO `operationtype` VALUES 
(1,'AddMotherboard'),
(2,'ModifyMotherboard'),
(3,'RemoveMotherboard'),
(4,'ActivateMotherboard'),
(5,'DeactivateMotherboard'),
(6,'AddCluster'),
(7,'ModifyCluster'),
(8,'RemoveCluster'),
(9,'ActivateCluster'),
(10,'DeactivateCluster'),
(11,'StartCluster'),
(12,'StopCluster'),
(13,'AddSystemimage'),
(14,'CloneSystemimage'),
(15,'ModifySystemimage'),
(16,'RemoveSystemimage'),
(17,'ActivateSystemimage'),
(18,'DeactivateSystemimage'),
(19,'AddMotherboardInCluster'),
(20,'RemoveMotherboardFromCluster'),
(21,'AddComponentToCluster'),
(22,'RemoveComponentFromCluster'),
(23,'StopNode');

INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,1); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,2); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,3); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,4); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,5); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,6); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,7); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,8); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,9); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,10); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,11); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,12); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,13); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,14); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,15); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,16); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,17); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,18); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,19); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,20); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,21); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,22); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,23); SET @eid := @eid +1;


-- components list
INSERT INTO `component` VALUES 
(1,'Lvm','2','Storage'),
(2,'Apache','2','Webserver'),
(3,'Iscsitarget','1','Export'),
(4,'Openiscsi','2','Exportclient'),
(5,'Dhcpd','3','Dhcpserver'),
(6,'Atftpd','0','Tftpserver'),
(7,'Snmpd','5','Monitoragent'),
(8,'Keepalived','1','Loadbalancer');
(9,'Mysql','5','DBserver');

-- kernels
INSERT INTO `kernel` VALUES (1,'admin','2.6.32','Admin Kernel');
INSERT INTO `kernel` VALUES (2,'2.6.26-2-486','2.6.26-2-486','');
INSERT INTO `kernel` VALUES (3,'2.6.26-2-xen-686','2.6.26-2-xen-686','');
INSERT INTO `kernel` VALUES (4,'2.6.26-hedera','2.6.26-hedera','');
INSERT INTO `kernel` VALUES (5,'2.6.30.1-hedera','2.6.30.1-hedera','');
INSERT INTO `kernel` VALUES (6,'2.6.31-hederatech-minix','2.6.31-hederatech-minix','');
INSERT INTO `kernel` VALUES (7,'2.6.31-hederatech-via-vb8001','2.6.31-hederatech-via-vb8001','');
INSERT INTO `kernel` VALUES (8,'2.6.31-hederatech-zotac-ion','2.6.31-hederatech-zotac-ion','');
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,1); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,2); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,3); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,4); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,5); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,6); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,7); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,8); SET @eid := @eid +1;

-- default distribution
INSERT INTO `distribution` VALUES (1,'Debian','5.0','Debian Lenny',1,2);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `distribution_entity` VALUES (@eid,1); SET @eid := @eid +1;

-- components provided by default distribution
INSERT INTO `component_provided` VALUES (4,1),(7,1);

-- default systemimage based on default distribution
INSERT INTO `systemimage` VALUES (1,'DebianSystemImage','default system image based on Debian 5.0 distribution', 1, 3, 4, 0);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `systemimage_entity` VALUES (@eid,1); SET @eid := @eid +1;
-- Webserver systemimage based on default distribution
INSERT INTO `systemimage` VALUES (2,'WebSystemImage','System Image optimize for Web server', 1, 5, 6, 0);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `systemimage_entity` VALUES (@eid,2); SET @eid := @eid +1;
-- DBserver systemimage based on default distribution
INSERT INTO `systemimage` VALUES (3,'DBSystemImage','System Image optimize for DB server', 1, 7, 8, 0);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `systemimage_entity` VALUES (@eid,3); SET @eid := @eid +1;
-- Testserver systemimage based on default distribution
INSERT INTO `systemimage` VALUES (4,'TestSystemImage','Test using Apache and Mysql on same system image.r', 1, 9, 10, 0);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `systemimage_entity` VALUES (@eid,4); SET @eid := @eid +1;
-- MailServer systemimage based on default distribution
INSERT INTO `systemimage` VALUES (5,'MailSystemImage','System image including postfix to send and receive mails', 1, 11, 12, 0);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `systemimage_entity` VALUES (@eid,5); SET @eid := @eid +1;


-- components installed on systemimage DebianSystemImage
INSERT INTO `component_installed` VALUES (2,1),(4,1),(7,1),(8,1),(9,1);
-- components installed on systemimage WebSystemImage
INSERT INTO `component_installed` VALUES (2,2),(4,2),(7,2),(8,2);
-- components installed on systemimage DBSystemImage
INSERT INTO `component_installed` VALUES (4,3),(7,3),(9,3);
-- components installed on systemimage TestSystemImage
INSERT INTO `component_installed` VALUES (2,4),(4,4),(7,4),(8,4),(9,4);
-- components installed on systemimage MailSystemImage
INSERT INTO `component_installed` VALUES (4,5),(7,5);

-- admin cluster
INSERT INTO `cluster` VALUES (1,'adm','Main Cluster hosting Administrator, Executor, Boot server and NAS',0,1,1,500,1,NULL,1, 'up');
INSERT INTO `entity` VALUES (@eid); INSERT INTO `cluster_entity` VALUES (@eid,1); SET @eid := @eid +1;
-- CRM Web cluster
INSERT INTO `cluster` VALUES (2,'WebCRM','Cluster hosting Web Interface of CRM',0,1,4,200,1,2,NULL, 'up');
INSERT INTO `entity` VALUES (@eid); INSERT INTO `cluster_entity` VALUES (@eid,2); SET @eid := @eid +1;
-- WebSite cluster
INSERT INTO `cluster` VALUES (3,'WebSite','Cluster hosting Web interface of official site',0,1,2,300,1,2,NULL, 'up');
INSERT INTO `entity` VALUES (@eid); INSERT INTO `cluster_entity` VALUES (@eid,3); SET @eid := @eid +1;
-- ERP Web cluster
INSERT INTO `cluster` VALUES (4,'WebERP','Cluster hosting Web Interface of ERP',0,1,2,250,1,2,NULL, 'up');
INSERT INTO `entity` VALUES (@eid); INSERT INTO `cluster_entity` VALUES (@eid,4); SET @eid := @eid +1;
-- MutualDB cluster
INSERT INTO `cluster` VALUES (5,'MutualDB','Cluster hosting DB for official web site and ERP',0,1,1,300,1,3,NULL, 'up');
INSERT INTO `entity` VALUES (@eid); INSERT INTO `cluster_entity` VALUES (@eid,5); SET @eid := @eid +1;
-- CRM DB cluster
INSERT INTO `cluster` VALUES (6,'CRMDB','Cluster hosting CRM Database',0,1,1,250,1,3,NULL, 'up');
INSERT INTO `entity` VALUES (@eid); INSERT INTO `cluster_entity` VALUES (@eid,6); SET @eid := @eid +1;

-- public ip for admin cluster
INSERT INTO `publicip` VALUES (1,'192.168.0.1','255.255.255.0',NULL,1); 
INSERT INTO `publicip` VALUES (2,'212.86.34.1','255.255.255.0','212.86.34.1',3); 
INSERT INTO `publicip` VALUES (3,'212.86.34.2','255.255.255.0','212.86.34.1',2); 
INSERT INTO `publicip` VALUES (4,'212.86.34.3','255.255.255.0','212.86.34.1',4); 
INSERT INTO `publicip` VALUES (5,'212.86.34.4','255.255.255.0','212.86.34.1',NULL); 
INSERT INTO `publicip` VALUES (6,'212.86.34.5','255.255.255.0','212.86.34.1',NULL); 
INSERT INTO `publicip` VALUES (7,'212.86.34.6','255.255.255.0','212.86.34.1',NULL);
 
-- admin motherboard
INSERT INTO `motherboard` VALUES (1,1,1,1,'Admin SN',1,'Admin motherboard',1,'00:1c:c0:c0:a9:1b','adm.hederatech.com','10.0.0.1','node001',NULL, 'up');
INSERT INTO `entity` VALUES (@eid); INSERT INTO `motherboard_entity` VALUES (@eid,1); SET @eid := @eid +1;

-- admin node
INSERT INTO `node` VALUES (1,1,1,1);

-- components templates
INSERT INTO `component_template` VALUES (1,'defaultapache','/templates/mcsapache2', 2);
INSERT INTO `component_template` VALUES (2,'mcsdhcpd','/templates/mcsdhcpd', 5);
INSERT INTO `component_template` VALUES (3,'mcssnmpd','/templates/mcssnmpd', 7);
INSERT INTO `component_template` VALUES (4,'mcskeepalived','/templates/mcskeepalived', 8);
INSERT INTO `component_template` VALUES (5,'mcsmysql','/templates/mcsmysql', 9);

-- initial components instance for admin cluster: 
INSERT INTO `component_instance` VALUES (1,1,1,NULL),(2,1,2,1),(3,1,3,NULL),(4,1,5,2),(5,1,6,NULL),(6,1,8,5);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,1); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,2); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,3); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,4); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,5); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,6); SET @eid := @eid +1;
-- initial components instance for WebCRM cluster: 
INSERT INTO `component_instance` VALUES (7,2,2,NULL),(8,2,4,1),(9,2,7,NULL),(10,2,8,NULL);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,7); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,8); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,9); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,10); SET @eid := @eid +1;
-- initial components instance for Website cluster: 
INSERT INTO `component_instance` VALUES (11,3,2,NULL),(12,3,4,1),(13,3,7,NULL),(14,3,8,NULL);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,11); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,12); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,13); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,14); SET @eid := @eid +1;
-- initial components instance for WebERB cluster: 
INSERT INTO `component_instance` VALUES (15,4,2,NULL),(16,4,4,1),(17,4,7,NULL),(18,4,8,NULL);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,15); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,16); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,17); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,18); SET @eid := @eid +1;
-- initial components instance for WebERB cluster: 
INSERT INTO `component_instance` VALUES (15,4,2,NULL),(16,4,4,1),(17,4,7,NULL),(18,4,8,NULL);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,15); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,16); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,17); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,18); SET @eid := @eid +1;
-- initial components instance for MutualDB cluster: 
INSERT INTO `component_instance` VALUES (19,5,4,NULL),(20,5,7,NULL),(21,5,9,NULL);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,19); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,20); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,21); SET @eid := @eid +1;
-- initial components instance for CRMDB cluster: 
INSERT INTO `component_instance` VALUES (22,6,4,NULL),(23,6,7,NULL),(24,6,9,NULL);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,22); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,23); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,24); SET @eid := @eid +1;

-- main vg storage from only one pv
INSERT INTO `lvm2_vg` VALUES (1,1,'vg1',65610,134190);
INSERT INTO `lvm2_pv` VALUES (1,1,'/dev/sda4');

-- distribution device for Debian 5.0
INSERT INTO `lvm2_lv` VALUES (1,1,'etc_Debian_5.0',52,0,'ext3');
INSERT INTO `lvm2_lv` VALUES (2,1,'root_Debian_5.0',6144,0,'ext3');
-- systemimage device for DebianSystemImage
INSERT INTO `lvm2_lv` VALUES (3,1,'etc_DebianSystemImage',52,0,'ext3');
INSERT INTO `lvm2_lv` VALUES (4,1,'root_DebianSystemImage',6144,0,'ext3');
-- systemimage device for WebSystemImage
INSERT INTO `lvm2_lv` VALUES (5,1,'etc_WebSystemImage',52,0,'ext3');
INSERT INTO `lvm2_lv` VALUES (6,1,'root_WebSystemImage',6144,0,'ext3');
-- systemimage device for DBSystemImage
INSERT INTO `lvm2_lv` VALUES (7,1,'etc_DBSystemImage',52,0,'ext3');
INSERT INTO `lvm2_lv` VALUES (8,1,'root_DBSystemImage',6144,0,'ext3');
-- systemimage device for TestSystemImage
INSERT INTO `lvm2_lv` VALUES (9,1,'etc_TestSystemImage',52,0,'ext3');
INSERT INTO `lvm2_lv` VALUES (10,1,'root_TestSystemImage',6144,0,'ext3');
-- systemimage device for DebianSystemImage
INSERT INTO `lvm2_lv` VALUES (11,1,'etc_MailSystemImage',52,0,'ext3');
INSERT INTO `lvm2_lv` VALUES (12,1,'root_MailSystemImage',6144,0,'ext3');

-- atftp configuration
INSERT INTO `atftpd0` VALUES (1,5,'--daemon --tftpd-timeout 300 --retry-timeout 5 --no-multicast --maxthread 100 --verbose=5', 'FALSE', '/var/log/atftpd.log','/tftp');

-- dhcpd configuration
INSERT INTO `dhcpd3` VALUES (1,4,'hedera-technology.com', '137.194.2.16','node001');
INSERT INTO `dhcpd3_subnet` VALUES (1,1,'10.0.0.0','255.255.255.0');

--
-- data for development tests
-- 

INSERT INTO `user` VALUES 
(2,'thom','pass','Thomas','MANNI','thomas.manni@hederatech.com',CURRENT_DATE(),NULL,''),(3,'xebech','pass','Antoine','CASTAING','antoine.castaing@hederatech.com',CURRENT_DATE(),NULL,''),
(4,'tortue','pass','Sylvain','YVON-PALIOT','sylvain.yvon-paliot@hederatech.com',CURRENT_DATE(),NULL,'');
INSERT INTO `entity` VALUES (@eid); INSERT INTO `user_entity` VALUES (@eid,2); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `user_entity` VALUES (@eid,3); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `user_entity` VALUES (@eid,4); SET @eid := @eid +1;

SET foreign_key_checks=1;





