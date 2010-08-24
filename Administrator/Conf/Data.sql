USE `administrator`;
SET foreign_key_checks=0;

--
-- permanents data
--

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
INSERT INTO `entity` VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10);
INSERT INTO `groups_entity` VALUES (1,1),(2,2),(3,3),(4,4),(5,5),(6,6),(7,7),(8,8),(9,9),(10,10);


INSERT INTO `user` VALUES (1,'executer','executer','executer','executer',NULL,'2010-07-22',NULL,'executer');
INSERT INTO `entity` VALUES (11);
INSERT INTO `user_entity` VALUES (11,1);


INSERT INTO `processor_model` VALUES (1,'Intel','Atom',2,2,0,2,17,0,0,NULL);
INSERT INTO `entity` VALUES (12);
INSERT INTO `processor_model_entity` VALUES (12,1);


INSERT INTO `motherboard_model` VALUES (1,'Intel','DG945GCLF2','945GC',2,42,1,1,2,1);
INSERT INTO `entity` VALUES (13);
INSERT INTO `motherboard_model_entity` VALUES (13,1);


INSERT INTO `operationtype` VALUES 
(1,'AddMotherboard'),
(2,'ModifyMotherboard'),
(3,'RemoveMotherboard'),
(4,'AddCluster'),
(5,'ModifyCluster'),
(6,'RemoveCluster'),
(7,'AddSystemimage'),
(8,'CloneSystemimage'),
(9,'ModifySystemimage'),
(10,'RemoveSystemimage'),
(11,'AddMotherboardInCluster'),
(12,'RemoveMotherboardFromCluster'),
(13,'AddComponentToCluster'),
(14,'RemoveComponentFromCluster');
INSERT INTO `entity` VALUES (14),(15),(16),(17),(18),(19),(20),(21),(22),(23),(24),(25),(26),(27);
INSERT INTO `operationtype_entity` VALUES (14,1),(15,2),(16,3),(17,4),(18,5),(19,6),(20,7),(21,8),
(22,9),(23,10),(24,11),(25,12),(26,13),(27,14);


INSERT INTO `component` VALUES 
(1,'Lvm','2','Storage'),
(2,'Apache','2','Webserver'),
(3,'Iscsitarget','1','Export'),
(4,'Openiscsi','2','ExportClient'),
(5,'Dhcpd','3','Dhcpserver'),
(6,'Atftpd','0','Tftpserver');


INSERT INTO `kernel` VALUES (1,'admin','2.6.32','Admin Kernel');
INSERT INTO `entity` VALUES (28);
INSERT INTO `kernel_entity` VALUES (28,1);


INSERT INTO `distribution` VALUES (1,'Debian','5.0','Debian Lenny',1,2);
INSERT INTO `entity` VALUES (29);
INSERT INTO `distribution_entity` VALUES (29,1);

INSERT INTO `component_provided` VALUES (1,1),(2,1),(3,1), (4,1);

INSERT INTO `cluster` VALUES (1,'adm','Main Cluster hosting Administrator, Executor, Boot server and NAS',0,1,1,500,1,NULL,1);
INSERT INTO `entity` VALUES (30);
INSERT INTO `cluster_entity` VALUES (30,1);

INSERT INTO `publicip` VALUES (1,'192.168.0.1','255.255.255.0',NULL,1); 

INSERT INTO `motherboard` VALUES (1,1,1,1,'Admin SN',1,'Admin motherboard',1,'00:1c:c0:c0:a9:1b','adm.hederatech.com','127.0.0.1','node001',NULL);
INSERT INTO `entity` VALUES (31);
INSERT INTO `motherboard_entity` VALUES (31,1);

INSERT INTO `node` VALUES (1,1,1,1);

INSERT INTO `component_template` VALUES (1,'defaultapache','/templates/defaultapache', 2);
INSERT INTO `component_template` VALUES (2,'mcsdhcpd','/templates/mcsdhcpd', 5);

-- initial components instance for admin cluster: 
INSERT INTO `component_instance` VALUES (1,1,1,NULL),(2,1,2,1),(3,1,3,NULL),(4,1,5,2),(5,1,6,NULL);
INSERT INTO `entity` VALUES (32),(33),(34),(35),(36) ;
INSERT INTO `component_instance_entity` VALUES (32,1),(33,2),(34,3),(35,4),(36,5);

-- main vg storage from only one pv
INSERT INTO `lvm2_vg` VALUES (1,1,'vg1',65610,134190);
INSERT INTO `lvm2_pv` VALUES (1,1,'/dev/sda4');

-- distribution device for debian 5
INSERT INTO `lvm2_lv` VALUES (1,1,'etc_Debian_5.0',52,0,'ext3');
INSERT INTO `lvm2_lv` VALUES (2,1,'root_Debian_5.0',100,0,'ext3');

-- atftp configuration
INSERT INTO `atftpd0` VALUES (1,6,'--daemon --tftpd-timeout 300 --retry-timeout 5 --no-multicast --maxthread 100 --verbose=5', 'FALSE', '/var/log/atftpd.log','/tftp');

-- dhcpd configuration
INSERT INTO `dhcpd3` VALUES (1,5,'hedera-technology.com', '137.194.2.16','10.0.0.0');
INSERT INTO `dhcpd3_subnet` VALUES (1,1,'10.0.0.0','255.255.255.0');


--
-- data for development tests
-- 

INSERT INTO `ingroups` VALUES (44,131),(35,132),(44,132),(35,133),(44,133),(35,134),(35,179),(35,180),(35,181);

INSERT INTO `user` VALUES 
(2,'thom','pass','Thomas','MANNI','thomas.manni@hederatech.com','2010-07-22',NULL,''),(3,'xebech','pass','Antoine','CASTAING','antoine.castaing@hederatech.com','2010-07-22',NULL,''),
(4,'tortue','pass','Sylvain','YVON-PALIOT','sylvain.yvon-paliot@hederatech.com','2010-07-22',NULL,''),(5,'titi','pass','titi','titi','titi@somewhere.com','2010-07-25',NULL,'Note concerning this user'),(6,'tata','pass','tata','tata','tata@somewhere.com','2010-07-25',NULL,'Note concerning this user'),(7,'toto','pass','toto','toto','toto@somewhere.com','2010-07-25',NULL,'Note concerning this user');
INSERT INTO `entity` VALUES (37),(38),(39),(40),(41),(42);
INSERT INTO `user_entity` VALUES (37,2),(38,3),(39,4),(40,5),(41,6),(42,7);

SET foreign_key_checks=1;





