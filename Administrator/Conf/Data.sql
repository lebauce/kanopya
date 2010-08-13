CREATE DATABASE  IF NOT EXISTS `administrator` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `administrator`;
-- MySQL dump 10.13  Distrib 5.1.41, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: administrator
-- ------------------------------------------------------
-- Server version	5.1.41-3ubuntu12.6


-- Dumping data for table `kernel`
--

LOCK TABLES `kernel` WRITE;
/*!40000 ALTER TABLE `kernel` DISABLE KEYS */;
INSERT INTO `kernel` VALUES (1,'admin','2.6.32','Admin Kernel');
/*!40000 ALTER TABLE `kernel` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `distribution_entity`
--

LOCK TABLES `distribution_entity` WRITE;
/*!40000 ALTER TABLE `distribution_entity` DISABLE KEYS */;
/*!40000 ALTER TABLE `distribution_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `processor_model`
--

LOCK TABLES `processor_model` WRITE;
/*!40000 ALTER TABLE `processor_model` DISABLE KEYS */;
INSERT INTO `processor_model` VALUES (1,'Intel','Atom',2,2,0,2,17,0,0,NULL);
/*!40000 ALTER TABLE `processor_model` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `motherboard`
--

LOCK TABLES `motherboard` WRITE;
/*!40000 ALTER TABLE `motherboard` DISABLE KEYS */;
INSERT INTO `motherboard` VALUES (1,1,1,1,'Admin SN',1,'Admin motherboard',1,'00:1c:c0:c0:a9:1b','adm.hederatech.com','127.0.0.1','node001',NULL),(2,1,1,1,'Test sn',0,NULL,0,'00:1c:c0:c0:1c:9a','test','10.0.0.1','node002',1),(3,1,1,1,'Test2 sn',0,NULL,0,'00:1c:c1:c1:c1:c1','test','10.0.0.2','node002',2);
/*!40000 ALTER TABLE `motherboard` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `component_provided`
--

LOCK TABLES `component_provided` WRITE;
/*!40000 ALTER TABLE `component_provided` DISABLE KEYS */;
INSERT INTO `component_provided` VALUES (1,1),(2,1),(3,1);
/*!40000 ALTER TABLE `component_provided` ENABLE KEYS */;
UNLOCK TABLES;


--
-- Dumping data for table `entity`
--

LOCK TABLES `entity` WRITE;
/*!40000 ALTER TABLE `entity` DISABLE KEYS */;
INSERT INTO `entity` VALUES (121,0),(122,0),(123,0),(124,0),(125,0),(126,0),(127,0),(128,0),(129,0),(130,0),(131,0),(132,0),(133,0),(134,0),(179,0),(180,0),(181,0),(182,0),(183,0),(184,0),(185,0),(186,0),(187,0),(188,0),(189,0),(190,0),(191,0),(192,0);
/*!40000 ALTER TABLE `entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `cluster`
--

LOCK TABLES `cluster` WRITE;
/*!40000 ALTER TABLE `cluster` DISABLE KEYS */;
INSERT INTO `cluster` VALUES (1,'adm','Admin Cluster',0,1,1,500,1,1,1);
/*!40000 ALTER TABLE `cluster` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `motherboard_model`
--

LOCK TABLES `motherboard_model` WRITE;
/*!40000 ALTER TABLE `motherboard_model` DISABLE KEYS */;
INSERT INTO `motherboard_model` VALUES (1,'Intel','DG945GCLF2','945GC',2,42,1,1,2,NULL);
/*!40000 ALTER TABLE `motherboard_model` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `operationtype`
--

LOCK TABLES `operationtype` WRITE;
/*!40000 ALTER TABLE `operationtype` DISABLE KEYS */;
INSERT INTO `operationtype` VALUES (10,'AddMotherboard');
/*!40000 ALTER TABLE `operationtype` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `motherboard_entity`
--

LOCK TABLES `motherboard_entity` WRITE;
/*!40000 ALTER TABLE `motherboard_entity` DISABLE KEYS */;
INSERT INTO `motherboard_entity` VALUES (185,1),(191,2),(192,3);
/*!40000 ALTER TABLE `motherboard_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `systemimage`
--

LOCK TABLES `systemimage` WRITE;
/*!40000 ALTER TABLE `systemimage` DISABLE KEYS */;
INSERT INTO `systemimage` VALUES (1,'SystemImageTest','desc SystemImageTest',1,0,0,0);
/*!40000 ALTER TABLE `systemimage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `message`
--

LOCK TABLES `message` WRITE;
/*!40000 ALTER TABLE `message` DISABLE KEYS */;
INSERT INTO `message` VALUES (1,15,'2010-07-29','16:50:50','info','mon premier message'),(2,15,'0000-00-00','16:52:35','INFO','ET BLABALBLA');
/*!40000 ALTER TABLE `message` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `component_instance`
--

LOCK TABLES `component_instance` WRITE;
/*!40000 ALTER TABLE `component_instance` DISABLE KEYS */;
INSERT INTO `component_instance` VALUES (1,1,1,NULL),(2,1,2,1),(3,1,3,NULL);
/*!40000 ALTER TABLE `component_instance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `openiscsi2`
--

LOCK TABLES `openiscsi2` WRITE;
/*!40000 ALTER TABLE `openiscsi2` DISABLE KEYS */;
/*!40000 ALTER TABLE `openiscsi2` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `component_template_attr`
--

LOCK TABLES `component_template_attr` WRITE;
/*!40000 ALTER TABLE `component_template_attr` DISABLE KEYS */;
/*!40000 ALTER TABLE `component_template_attr` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `component_instance_entity`
--

LOCK TABLES `component_instance_entity` WRITE;
/*!40000 ALTER TABLE `component_instance_entity` DISABLE KEYS */;
INSERT INTO `component_instance_entity` VALUES (188,1),(189,2),(190,3);
/*!40000 ALTER TABLE `component_instance_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `component_installed`
--

LOCK TABLES `component_installed` WRITE;
/*!40000 ALTER TABLE `component_installed` DISABLE KEYS */;
INSERT INTO `component_installed` VALUES (1,1),(2,1),(3,1);
/*!40000 ALTER TABLE `component_installed` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `operation`
--

LOCK TABLES `operation` WRITE;
/*!40000 ALTER TABLE `operation` DISABLE KEYS */;
/*!40000 ALTER TABLE `operation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `iscsitarget1_lun`
--

LOCK TABLES `iscsitarget1_lun` WRITE;
/*!40000 ALTER TABLE `iscsitarget1_lun` DISABLE KEYS */;
/*!40000 ALTER TABLE `iscsitarget1_lun` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `operation_entity`
--

LOCK TABLES `operation_entity` WRITE;
/*!40000 ALTER TABLE `operation_entity` DISABLE KEYS */;
/*!40000 ALTER TABLE `operation_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `apache2`
--

LOCK TABLES `apache2` WRITE;
/*!40000 ALTER TABLE `apache2` DISABLE KEYS */;
/*!40000 ALTER TABLE `apache2` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `publicip`
--

LOCK TABLES `publicip` WRITE;
/*!40000 ALTER TABLE `publicip` DISABLE KEYS */;
INSERT INTO `publicip` VALUES (1,'1','2',NULL,1);
/*!40000 ALTER TABLE `publicip` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `node`
--

LOCK TABLES `node` WRITE;
/*!40000 ALTER TABLE `node` DISABLE KEYS */;
INSERT INTO `node` VALUES (1,1,1,1);
/*!40000 ALTER TABLE `node` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `cluster_entity`
--

LOCK TABLES `cluster_entity` WRITE;
/*!40000 ALTER TABLE `cluster_entity` DISABLE KEYS */;
INSERT INTO `cluster_entity` VALUES (187,1);
/*!40000 ALTER TABLE `cluster_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `component`
--

LOCK TABLES `component` WRITE;
/*!40000 ALTER TABLE `component` DISABLE KEYS */;
INSERT INTO `component` VALUES (1,'Lvm','2','Storage'),(2,'Apache','2','Webserver'),(3,'Iscsitarget','1','Export'),(4,'Openiscsi','2','ExportClient');
/*!40000 ALTER TABLE `component` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `groups_entity`
--

LOCK TABLES `groups_entity` WRITE;
/*!40000 ALTER TABLE `groups_entity` DISABLE KEYS */;
INSERT INTO `groups_entity` VALUES (121,35),(122,36),(123,37),(124,38),(125,39),(126,40),(127,41),(128,42),(129,43),(130,44);
/*!40000 ALTER TABLE `groups_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `iscsitarget1_target`
--

LOCK TABLES `iscsitarget1_target` WRITE;
/*!40000 ALTER TABLE `iscsitarget1_target` DISABLE KEYS */;
/*!40000 ALTER TABLE `iscsitarget1_target` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `ingroups`
--

LOCK TABLES `ingroups` WRITE;
/*!40000 ALTER TABLE `ingroups` DISABLE KEYS */;
INSERT INTO `ingroups` VALUES (44,131),(35,132),(44,132),(35,133),(44,133),(35,134),(35,179),(35,180),(35,181);
/*!40000 ALTER TABLE `ingroups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `operation_parameter`
--

LOCK TABLES `operation_parameter` WRITE;
/*!40000 ALTER TABLE `operation_parameter` DISABLE KEYS */;
/*!40000 ALTER TABLE `operation_parameter` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (14,'executer','executer','executer','executer',NULL,'2010-07-22',NULL,'executer'),(15,'thom','pass','Thomas','MANNI','thomas.manni@hederatech.com','2010-07-22',NULL,''),(16,'xebech','pass','Antoine','CASTAING','antoine.castaing@hederatech.com','2010-07-22',NULL,''),(17,'tortue','pass','Sylvain','YVON-PALIOT','sylvain.yvon-paliot@hederatech.com','2010-07-22',NULL,''),(18,'titi','pass','titi','titi','titi@somewhere.com','2010-07-25',NULL,'Note concerning this user'),(19,'tata','pass','tata','tata','tata@somewhere.com','2010-07-25',NULL,'Note concerning this user'),(20,'toto','pass','toto','toto','toto@somewhere.com','2010-07-25',NULL,'Note concerning this user');
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `groups`
--

LOCK TABLES `groups` WRITE;
/*!40000 ALTER TABLE `groups` DISABLE KEYS */;
INSERT INTO `groups` VALUES (35,'User','User master group',1),(36,'Processortemplate','Processortemplate master group',1),(37,'Motherboardtemplate','Motherboardtemplate master group',1),(38,'Motherboard','Motherboard master group',1),(39,'Cluster','Cluster master group',1),(40,'Distribution','Distribution master group',1),(41,'Kernel','Kernel master group',1),(42,'Systemimage','Systemimage master group',1),(43,'Operationtype','Operationtype master group',1),(44,'admin','for administration tasks',1);
/*!40000 ALTER TABLE `groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `motherboarddetails`
--

LOCK TABLES `motherboarddetails` WRITE;
/*!40000 ALTER TABLE `motherboarddetails` DISABLE KEYS */;
/*!40000 ALTER TABLE `motherboarddetails` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `motherboard_model_entity`
--

LOCK TABLES `motherboard_model_entity` WRITE;
/*!40000 ALTER TABLE `motherboard_model_entity` DISABLE KEYS */;
INSERT INTO `motherboard_model_entity` VALUES (182,1);
/*!40000 ALTER TABLE `motherboard_model_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `processor_model_entity`
--

LOCK TABLES `processor_model_entity` WRITE;
/*!40000 ALTER TABLE `processor_model_entity` DISABLE KEYS */;
INSERT INTO `processor_model_entity` VALUES (184,1);
/*!40000 ALTER TABLE `processor_model_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `lvm2_pv`
--

LOCK TABLES `lvm2_pv` WRITE;
/*!40000 ALTER TABLE `lvm2_pv` DISABLE KEYS */;
INSERT INTO `lvm2_pv` VALUES (1,1,'/dev/sda4');
/*!40000 ALTER TABLE `lvm2_pv` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `component_template`
--

LOCK TABLES `component_template` WRITE;
/*!40000 ALTER TABLE `component_template` DISABLE KEYS */;
INSERT INTO `component_template` VALUES (1,'defaultapache','/templates/defaultapache');
/*!40000 ALTER TABLE `component_template` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `route`
--

LOCK TABLES `route` WRITE;
/*!40000 ALTER TABLE `route` DISABLE KEYS */;
/*!40000 ALTER TABLE `route` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `operationtype_entity`
--

LOCK TABLES `operationtype_entity` WRITE;
/*!40000 ALTER TABLE `operationtype_entity` DISABLE KEYS */;
/*!40000 ALTER TABLE `operationtype_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `entityright`
--

LOCK TABLES `entityright` WRITE;
/*!40000 ALTER TABLE `entityright` DISABLE KEYS */;
INSERT INTO `entityright` VALUES (2,128,121,2),(3,121,121,2),(4,121,121,2),(6,121,130,7),(7,129,130,1),(8,129,121,2),(16,121,180,4);
/*!40000 ALTER TABLE `entityright` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `message_entity`
--

LOCK TABLES `message_entity` WRITE;
/*!40000 ALTER TABLE `message_entity` DISABLE KEYS */;
/*!40000 ALTER TABLE `message_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `kernel_entity`
--

LOCK TABLES `kernel_entity` WRITE;
/*!40000 ALTER TABLE `kernel_entity` DISABLE KEYS */;
INSERT INTO `kernel_entity` VALUES (183,1);
/*!40000 ALTER TABLE `kernel_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `systemimage_entity`
--

LOCK TABLES `systemimage_entity` WRITE;
/*!40000 ALTER TABLE `systemimage_entity` DISABLE KEYS */;
INSERT INTO `systemimage_entity` VALUES (186,1);
/*!40000 ALTER TABLE `systemimage_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `distribution`
--

LOCK TABLES `distribution` WRITE;
/*!40000 ALTER TABLE `distribution` DISABLE KEYS */;
INSERT INTO `distribution` VALUES (1,'Debian','5.0','First Debian',1,0);
/*!40000 ALTER TABLE `distribution` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `lvm2_lv`
--

LOCK TABLES `lvm2_lv` WRITE;
/*!40000 ALTER TABLE `lvm2_lv` DISABLE KEYS */;
INSERT INTO `lvm2_lv` VALUES (1,'etc_00_1c_c0_c0_1c_9a',0,1,52,'ext3'),(1,'etc_00_1c_c1_c1_c1_c1',0,2,52,'ext3');
/*!40000 ALTER TABLE `lvm2_lv` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `lvm2_vg`
--

LOCK TABLES `lvm2_vg` WRITE;
/*!40000 ALTER TABLE `lvm2_vg` DISABLE KEYS */;
INSERT INTO `lvm2_vg` VALUES (1,1,'vg1',65610,134190);
/*!40000 ALTER TABLE `lvm2_vg` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping data for table `user_entity`
--

LOCK TABLES `user_entity` WRITE;
/*!40000 ALTER TABLE `user_entity` DISABLE KEYS */;
INSERT INTO `user_entity` VALUES (131,14),(132,15),(133,16),(134,17),(179,18),(180,19),(181,20);
/*!40000 ALTER TABLE `user_entity` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2010-08-13 12:10:24
