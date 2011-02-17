USE `administrator`;
SET foreign_key_checks=0;
SET @eid := 1;

--
-- permanents data
--

-- system groups
INSERT INTO `groups` VALUES 
(1,'User','User', 'User master group containing all users',1),
(2,'Processormodel','Processormodel','Processormodel master group containing all processor models',1),
(3,'Motherboardmodel','Motherboardmodel','Motherboardmodel master group containing all motherboard models',1),
(4,'Motherboard','Motherboard','Motherboard master group containing all motherboards',1),
(5,'Cluster','Cluster','Cluster master group containing all clusters',1),
(6,'Distribution','Distribution','Distribution master group all distributions',1),
(7,'Kernel','Kernel','Kernel master group containing all kernels',1),
(8,'Systemimage','Systemimage','Systemimage master group containing all system images',1),
(9,'Operationtype','Operationtype','Operationtype master group containing all operations',1),
(10,'Powersupplycardmodel','Powersupplycardmodel','Powersupplycardmodel master group  containing all powersupply card models',1),
(11,'Powersupplycard','Powersupplycard','Powersupplycard master group  containing all power supply cards',1),
(12,'Groups','Groups','Groups master group containing all groups',1);

INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,1); SET @MasterUserGroup_eid = @eid; SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,2); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,3); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,4); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,5); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,6); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,7); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,8); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,9); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,10); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,11); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,12); SET @eid := @eid +1;

-- predefined groups
INSERT INTO `groups` VALUES
(13,'Admin','User','Privileged users for administration tasks',0);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,13); SET @eid := @eid +1;
SET @Admin_group_id = 13;

INSERT INTO `groups` VALUES
(14,'GuestGroup','User','Guest users with limited permissions',0);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `groups_entity` VALUES (@eid,14); SET @GuestGroup_eid = @eid; SET @eid := @eid +1;
SET @Guest_group_id = 14;

-- system user
INSERT INTO `user` VALUES 
(1,1,'executer','executer','executer','executer',NULL,CURRENT_DATE(),NULL,'executer');
INSERT INTO `entity` VALUES (@eid); INSERT INTO `user_entity` VALUES (@eid,1); SET @eid := @eid +1;

-- predefined user
INSERT INTO `user` VALUES
(2,1,'admin','admin','Administrator','','admin@somewhere.com',CURRENT_DATE(),NULL,'God user for administrative tasks.');
INSERT INTO `entity` VALUES (@eid); INSERT INTO `user_entity` VALUES (@eid,2); 
INSERT INTO `ingroups` VALUES (@Admin_group_id, @eid); SET @eid := @eid +1;

INSERT INTO `user` VALUES (3,0,'guest','guest','Guest','','guest@somewhere.com',CURRENT_DATE(),NULL,'Guest user with limited permissions.');
INSERT INTO `entity` VALUES (@eid); INSERT INTO `user_entity` VALUES (@eid,3); 
INSERT INTO `ingroups` VALUES (@Guest_group_id, @eid); 
SET @guest_user_eid = @eid;
SET @eid := @eid +1;

-- processor models
INSERT INTO `processormodel` VALUES (1,'Intel','Atom 330',2,1.6,1,8,1);
INSERT INTO `processormodel` VALUES (2,'Intel','Atom D510',2,1.66,1,13,1);
INSERT INTO `processormodel` VALUES (3,'VIA Nano','L2200',2,1.6,1,13,1);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `processormodel_entity` VALUES (@eid,1); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `processormodel_entity` VALUES (@eid,2); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `processormodel_entity` VALUES (@eid,3); SET @eid := @eid +1;

-- powersupplycard models
INSERT INTO `powersupplycardmodel` VALUES (1,'HEDERATECH','notresupermodeldecarte',12);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `powersupplycardmodel_entity` VALUES (@eid,1); SET @eid := @eid +1;

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
(23,'StopNode'),
(24,'UpdateClusterNodeStarted'),
(25,'PreStartNode'),
(26,'StartNode'),
(27,'PreStopNode'),
(28,'PostStopNode'),
(29,'PostStartNode');

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
INSERT INTO `entity` VALUES (@eid); INSERT INTO `operationtype_entity` VALUES (@eid,24); SET @eid := @eid +1;

-- components list
INSERT INTO `component` VALUES 
(1,'Lvm','2','Storage'),
(2,'Apache','2','Webserver'),
(3,'Iscsitarget','1','Export'),
(4,'Openiscsi','2','Exportclient'),
(5,'Dhcpd','3','Dhcpserver'),
(6,'Atftpd','0','Tftpserver'),
(7,'Snmpd','5','Monitoragent'),
(8,'Keepalived','1','Loadbalancer'),
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
INSERT INTO `kernel` VALUES (9,'2.6.35.4-hedera','2.6.35.4-hedera','');

INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,1); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,2); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,3); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,4); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,5); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,6); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,7); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,8); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `kernel_entity` VALUES (@eid,9); SET @eid := @eid +1;

-- Power Supply Card
INSERT INTO `powersupplycard` VALUE (1,'InternalCard','10.0.0.220',1,'00:30:f9:05:8b:6e',1);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `powersupplycard_entity` VALUES (@eid,1); SET @eid := @eid +1;

-- Power Supply
INSERT INTO `powersupply` VALUE (1,1,1);

-- default distribution
INSERT INTO `distribution` VALUES (1,'Debian','5.0','Debian Lenny',1,2);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `distribution_entity` VALUES (@eid,1); SET @eid := @eid +1;

-- components provided by default distribution
INSERT INTO `component_provided` VALUES (2,1),(3,1),(4,1),(5,1),(6,1),(7,1),(8,1),(9,1);

-- default systemimage based on default distribution
INSERT INTO `systemimage` VALUES (1,'DebianSystemImage','default system image based on Debian 5.0 distribution', 1, 3, 4, 0);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `systemimage_entity` VALUES (@eid,1); SET @eid := @eid +1;

-- components installed on systemimage DebianSystemImage
INSERT INTO `component_installed` VALUES (2,1),(4,1),(7,1),(8,1);

-- admin cluster
INSERT INTO `cluster` VALUES (1,'adm','Main Cluster hosting Administrator, Executor, Boot server and NAS',0,1,1,500,1,NULL,1, 'up');
INSERT INTO `entity` VALUES (@eid); INSERT INTO `cluster_entity` VALUES (@eid,1); SET @eid := @eid +1;

-- public ip for admin cluster
INSERT INTO `ipv4_public` VALUES (1,'192.168.0.1','255.255.255.0',NULL,1); 

-- internal ip for admin node
INSERT INTO `ipv4_internal` VALUES (1,'10.0.0.1','255.255.255.0', NULL);

-- admin motherboard
INSERT INTO `motherboard` VALUES (1,6,2,9,'SN102050046322',1,'Admin motherboard',1,'6c:f0:49:d1:dc:9f','node1.hederatech.com',1,'node001',NULL, 'up');
INSERT INTO `entity` VALUES (@eid); INSERT INTO `motherboard_entity` VALUES (@eid,1); SET @eid := @eid +1;

-- admin node
INSERT INTO `node` VALUES (1,1,1,1,'in');

-- components templates
INSERT INTO `component_template` VALUES (1,'defaultapache','/templates/components/mcsapache2', 2);
INSERT INTO `component_template` VALUES (2,'mcsdhcpd','/templates/components/mcsdhcpd', 5);
INSERT INTO `component_template` VALUES (3,'mcssnmpd','/templates/components/mcssnmpd', 7);
INSERT INTO `component_template` VALUES (4,'mcskeepalived','/templates/components/mcskeepalived', 8);

-- initial components instance for admin cluster: 
INSERT INTO `component_instance` VALUES (1,1,1,NULL),(2,1,2,1),(3,1,3,NULL),(4,1,5,2),(5,1,6,NULL);
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,1); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,2); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,3); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,4); SET @eid := @eid +1;
INSERT INTO `entity` VALUES (@eid); INSERT INTO `component_instance_entity` VALUES (@eid,5); SET @eid := @eid +1;

-- main vg storage from only one pv
INSERT INTO `lvm2_vg` VALUES (1,1,'vg1',65610,134190);
INSERT INTO `lvm2_pv` VALUES (1,1,'/dev/sda4');

-- distribution device for Debian 5.0
INSERT INTO `lvm2_lv` VALUES (1,1,'etc_Debian_5.0',52,0,'ext3');
INSERT INTO `lvm2_lv` VALUES (2,1,'root_Debian_5.0',6144,0,'ext3');
-- systemimage device for DebianSystemImage
INSERT INTO `lvm2_lv` VALUES (3,1,'etc_DebianSystemImage',52,0,'ext3');
INSERT INTO `lvm2_lv` VALUES (4,1,'root_DebianSystemImage',6144,0,'ext3');

-- atftp configuration
INSERT INTO `atftpd0` VALUES (1,5,'--daemon --tftpd-timeout 300 --retry-timeout 5 --no-multicast --maxthread 100 --verbose=5', 'FALSE', '/var/log/atftpd.log','/tftp');

-- dhcpd configuration
INSERT INTO `dhcpd3` VALUES (1,4,'hedera-technology.com', '137.194.2.16','node001');
INSERT INTO `dhcpd3_subnet` VALUES (1,1,'10.0.0.0','255.255.255.0');


-- Monitoring
INSERT INTO `indicatorset` VALUES 
(1,'mem','SnmpProvider','GAUGE', null, 'Total'),
(2,'cpu','SnmpProvider','COUNTER', null, 'User+Idle+Wait+Nice+Syst+Kernel+Interrupt'),
(3,'apache_stats','ApacheProvider','DERIVE', 'Apache', null),
(4,'apache_workers','ApacheProvider','GAUGE', 'Apache', null);

INSERT INTO `indicator` VALUES 
(1,'Total','.1.3.6.1.4.1.2021.4.5.0',null,null,'FFFF0066', 1),
(2,'Avail','.1.3.6.1.4.1.2021.4.6.0',null,null,'00FF0066', 1),
(3,'Buffered','.1.3.6.1.4.1.2021.4.14.0',null,null,'0000FF66', 1),
(4,'Cached','.1.3.6.1.4.1.2021.4.15.0',null,null,'FF000066', 1),
(5,'User','.1.3.6.1.4.1.2021.11.50.0',null,null,'0000FF66', 2),
(6,'Wait','.1.3.6.1.4.1.2021.11.54.0',null,null,'FF000066', 2),
(7,'Nice','.1.3.6.1.4.1.2021.11.51.0',null,null,'FFFF0066', 2),
(8,'Syst','.1.3.6.1.4.1.2021.11.52.0',null,null,'00FFFF66', 2),
(9,'Kernel','.1.3.6.1.4.1.2021.11.55.0',null,null,'FF00FF66', 2),
(10,'Interrupt','.1.3.6.1.4.1.2021.11.56.0',null,null,'66666666', 2),
(11,'Idle','.1.3.6.1.4.1.2021.11.53.0',null,null,'00FF0066', 2),
(12,'ReqPerSec','Total Accesses',0,null,'0000FF99', 3),
(13,'IdleWorkers','IdleWorkers',null,null,'00FF0099', 4),
(14,'BusyWorkers','BusyWorkers',null,null,'FF000099', 4);

-- initial permissions for user guest
INSERT INTO `entityright` VALUES (1, @guest_user_eid, @guest_user_eid, 'get');
INSERT INTO `entityright` VALUES (2, @guest_user_eid, @guest_user_eid, 'update');
INSERT INTO `entityright` VALUES (3, @MasterUserGroup_eid, @guest_user_eid, 'get');
INSERT INTO `entityright` VALUES (4, @GuestGroup_eid, @guest_user_eid, 'get');

SET foreign_key_checks=1;





