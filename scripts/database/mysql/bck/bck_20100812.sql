CREATE DATABASE  IF NOT EXISTS `administrator` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `administrator`;
-- MySQL dump 10.13  Distrib 5.1.41, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: administrator
-- ------------------------------------------------------
-- Server version	5.1.41-3ubuntu12.6

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `kernel`
--

DROP TABLE IF EXISTS `kernel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kernel` (
  `kernel_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `kernel_name` char(64) NOT NULL,
  `kernel_version` char(32) NOT NULL,
  `kernel_desc` char(255) DEFAULT NULL,
  PRIMARY KEY (`kernel_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `kernel`
--

LOCK TABLES `kernel` WRITE;
/*!40000 ALTER TABLE `kernel` DISABLE KEYS */;
INSERT INTO `kernel` VALUES (1,'admin','2.6.32','Admin Kernel');
/*!40000 ALTER TABLE `kernel` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `distribution_entity`
--

DROP TABLE IF EXISTS `distribution_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `distribution_entity` (
  `entity_id` int(8) unsigned NOT NULL,
  `distribution_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`entity_id`,`distribution_id`),
  UNIQUE KEY `fk_distribution_entity_1` (`entity_id`),
  UNIQUE KEY `fk_distribution_entity_2` (`distribution_id`),
  CONSTRAINT `fk_distribution_entity_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_distribution_entity_2` FOREIGN KEY (`distribution_id`) REFERENCES `distribution` (`distribution_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `distribution_entity`
--

LOCK TABLES `distribution_entity` WRITE;
/*!40000 ALTER TABLE `distribution_entity` DISABLE KEYS */;
/*!40000 ALTER TABLE `distribution_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `processor_model`
--

DROP TABLE IF EXISTS `processor_model`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `processor_model` (
  `processor_model_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `processor_brand` char(64) NOT NULL,
  `processor_model` char(32) NOT NULL,
  `processor_core_num` int(2) unsigned NOT NULL,
  `processor_clock_speed` int(2) unsigned NOT NULL,
  `processor_FSB` int(2) unsigned NOT NULL,
  `processor_L2_cache` int(2) unsigned NOT NULL,
  `processor_max_consumption` int(2) unsigned NOT NULL,
  `processor_max_TDP` int(2) unsigned NOT NULL,
  `processor_64bits` int(1) unsigned NOT NULL,
  `processor_CPU_flags` char(255) DEFAULT NULL,
  PRIMARY KEY (`processor_model_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `processor_model`
--

LOCK TABLES `processor_model` WRITE;
/*!40000 ALTER TABLE `processor_model` DISABLE KEYS */;
INSERT INTO `processor_model` VALUES (1,'Intel','Atom',2,2,0,2,17,0,0,NULL);
/*!40000 ALTER TABLE `processor_model` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `motherboard`
--

DROP TABLE IF EXISTS `motherboard`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `motherboard` (
  `motherboard_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `motherboard_model_id` int(8) unsigned NOT NULL,
  `processor_model_id` int(8) unsigned NOT NULL,
  `kernel_id` int(8) unsigned NOT NULL,
  `motherboard_serial_number` char(64) NOT NULL,
  `motherboard_slot_position` int(1) unsigned NOT NULL,
  `motherboard_desc` char(255) DEFAULT NULL,
  `active` int(1) unsigned NOT NULL,
  `motherboard_mac_address` char(18) NOT NULL,
  `motherboard_initiatorname` char(64) DEFAULT NULL,
  `motherboard_internal_ip` char(15) DEFAULT NULL,
  `motherboard_hostname` char(32) DEFAULT NULL,
  `etc_device_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`motherboard_id`),
  UNIQUE KEY `motherboard_internal_ip_UNIQUE` (`motherboard_internal_ip`),
  KEY `fk_motherboard_1` (`motherboard_model_id`),
  KEY `fk_motherboard_2` (`processor_model_id`),
  KEY `fk_motherboard_3` (`kernel_id`),
  KEY `fk_motherboard_4` (`etc_device_id`),
  CONSTRAINT `fk_motherboard_1` FOREIGN KEY (`motherboard_model_id`) REFERENCES `motherboard_model` (`motherboard_model_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_motherboard_2` FOREIGN KEY (`processor_model_id`) REFERENCES `processor_model` (`processor_model_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_motherboard_3` FOREIGN KEY (`kernel_id`) REFERENCES `kernel` (`kernel_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_motherboard_4` FOREIGN KEY (`etc_device_id`) REFERENCES `lvm2_lv` (`lvm2_lv_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `motherboard`
--

LOCK TABLES `motherboard` WRITE;
/*!40000 ALTER TABLE `motherboard` DISABLE KEYS */;
INSERT INTO `motherboard` VALUES (1,1,1,1,'Admin SN',1,'Admin motherboard',1,'00:1c:c0:c0:a9:1b','adm.hederatech.com','127.0.0.1','node001',NULL);
/*!40000 ALTER TABLE `motherboard` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `component_provided`
--

DROP TABLE IF EXISTS `component_provided`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `component_provided` (
  `component_id` int(8) unsigned NOT NULL,
  `distribution_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`component_id`,`distribution_id`),
  KEY `fk_component_provided_1` (`component_id`),
  KEY `fk_component_provided_2` (`distribution_id`),
  CONSTRAINT `fk_component_provided_1` FOREIGN KEY (`component_id`) REFERENCES `component` (`component_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_component_provided_2` FOREIGN KEY (`distribution_id`) REFERENCES `distribution` (`distribution_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `component_provided`
--

LOCK TABLES `component_provided` WRITE;
/*!40000 ALTER TABLE `component_provided` DISABLE KEYS */;
INSERT INTO `component_provided` VALUES (1,1),(2,1);
/*!40000 ALTER TABLE `component_provided` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `clusterdetails`
--

DROP TABLE IF EXISTS `clusterdetails`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `clusterdetails` (
  `cluster_id` int(8) unsigned NOT NULL,
  `name` char(32) NOT NULL,
  `value` char(255) NOT NULL,
  PRIMARY KEY (`cluster_id`,`name`),
  KEY `fk_clusterdetails_1` (`cluster_id`),
  CONSTRAINT `fk_clusterdetails_1` FOREIGN KEY (`cluster_id`) REFERENCES `cluster` (`cluster_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clusterdetails`
--

LOCK TABLES `clusterdetails` WRITE;
/*!40000 ALTER TABLE `clusterdetails` DISABLE KEYS */;
/*!40000 ALTER TABLE `clusterdetails` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `entity`
--

DROP TABLE IF EXISTS `entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `entity` (
  `entity_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `unused` int(1) DEFAULT '0',
  PRIMARY KEY (`entity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=191 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `entity`
--

LOCK TABLES `entity` WRITE;
/*!40000 ALTER TABLE `entity` DISABLE KEYS */;
INSERT INTO `entity` VALUES (121,0),(122,0),(123,0),(124,0),(125,0),(126,0),(127,0),(128,0),(129,0),(130,0),(131,0),(132,0),(133,0),(134,0),(179,0),(180,0),(181,0),(182,0),(183,0),(184,0),(185,0),(186,0),(187,0),(188,0),(189,0),(190,0);
/*!40000 ALTER TABLE `entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cluster`
--

DROP TABLE IF EXISTS `cluster`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cluster` (
  `cluster_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `cluster_name` char(32) NOT NULL,
  `cluster_desc` char(255) DEFAULT NULL,
  `cluster_type` int(1) unsigned DEFAULT NULL,
  `cluster_min_node` int(2) unsigned NOT NULL,
  `cluster_max_node` int(2) unsigned NOT NULL,
  `cluster_priority` int(1) unsigned NOT NULL,
  `active` int(1) unsigned NOT NULL,
  `systemimage_id` int(8) unsigned NOT NULL,
  `kernel_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`cluster_id`),
  UNIQUE KEY `cluster_name` (`cluster_name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cluster`
--

LOCK TABLES `cluster` WRITE;
/*!40000 ALTER TABLE `cluster` DISABLE KEYS */;
INSERT INTO `cluster` VALUES (1,'adm','Admin Cluster',0,1,1,500,1,1,1);
/*!40000 ALTER TABLE `cluster` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `motherboard_model`
--

DROP TABLE IF EXISTS `motherboard_model`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `motherboard_model` (
  `motherboard_model_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `motherboard_brand` char(64) NOT NULL,
  `motherboard_model_name` char(32) NOT NULL,
  `motherboard_chipset` char(64) NOT NULL,
  `motherboard_processor_num` int(1) unsigned NOT NULL,
  `motherboard_consumption` int(2) unsigned NOT NULL,
  `motherboard_iface_num` int(1) unsigned NOT NULL,
  `motherboard_RAM_slot_num` int(1) unsigned NOT NULL,
  `motherboard_RAM_max` int(1) unsigned NOT NULL,
  `processor_model_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`motherboard_model_id`),
  UNIQUE KEY `motherboard_model_UNIQUE` (`motherboard_model_name`),
  KEY `fk_motherboard_model_1` (`processor_model_id`),
  CONSTRAINT `fk_motherboard_model_1` FOREIGN KEY (`processor_model_id`) REFERENCES `processor_model` (`processor_model_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `motherboard_model`
--

LOCK TABLES `motherboard_model` WRITE;
/*!40000 ALTER TABLE `motherboard_model` DISABLE KEYS */;
INSERT INTO `motherboard_model` VALUES (1,'Intel','DG945GCLF2','945GC',2,42,1,1,2,NULL);
/*!40000 ALTER TABLE `motherboard_model` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `operationtype`
--

DROP TABLE IF EXISTS `operationtype`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `operationtype` (
  `operationtype_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `operationtype_name` char(64) DEFAULT NULL,
  PRIMARY KEY (`operationtype_id`),
  UNIQUE KEY `operationtype_name_UNIQUE` (`operationtype_name`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `operationtype`
--

LOCK TABLES `operationtype` WRITE;
/*!40000 ALTER TABLE `operationtype` DISABLE KEYS */;
INSERT INTO `operationtype` VALUES (10,'AddMotherboard');
/*!40000 ALTER TABLE `operationtype` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `motherboard_entity`
--

DROP TABLE IF EXISTS `motherboard_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `motherboard_entity` (
  `entity_id` int(8) unsigned NOT NULL,
  `motherboard_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`entity_id`,`motherboard_id`),
  UNIQUE KEY `fk_motherboard_entity_1` (`entity_id`),
  UNIQUE KEY `fk_motherboard_entity_2` (`motherboard_id`),
  CONSTRAINT `fk_motherboard_entity_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_motherboard_entity_2` FOREIGN KEY (`motherboard_id`) REFERENCES `motherboard` (`motherboard_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `motherboard_entity`
--

LOCK TABLES `motherboard_entity` WRITE;
/*!40000 ALTER TABLE `motherboard_entity` DISABLE KEYS */;
INSERT INTO `motherboard_entity` VALUES (185,1);
/*!40000 ALTER TABLE `motherboard_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `systemimage`
--

DROP TABLE IF EXISTS `systemimage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `systemimage` (
  `systemimage_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `systemimage_name` char(32) NOT NULL,
  `systemimage_desc` char(255) DEFAULT NULL,
  `distribution_id` int(8) unsigned NOT NULL,
  `etc_device_id` int(8) unsigned NOT NULL,
  `root_device_id` int(8) unsigned NOT NULL,
  `systemimage_active` int(1) unsigned NOT NULL,
  PRIMARY KEY (`systemimage_id`),
  KEY `fk_systemimage_1` (`distribution_id`),
  CONSTRAINT `fk_systemimage_1` FOREIGN KEY (`distribution_id`) REFERENCES `distribution` (`distribution_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `systemimage`
--

LOCK TABLES `systemimage` WRITE;
/*!40000 ALTER TABLE `systemimage` DISABLE KEYS */;
INSERT INTO `systemimage` VALUES (1,'SystemImageTest','desc SystemImageTest',1,0,0,0);
/*!40000 ALTER TABLE `systemimage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `message`
--

DROP TABLE IF EXISTS `message`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `message` (
  `message_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(8) unsigned DEFAULT NULL,
  `message_creationdate` date NOT NULL,
  `message_creationtime` time NOT NULL,
  `message_type` char(32) NOT NULL,
  `message_content` char(255) NOT NULL,
  PRIMARY KEY (`message_id`),
  KEY `fk_message_1` (`user_id`),
  CONSTRAINT `fk_message_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `message`
--

LOCK TABLES `message` WRITE;
/*!40000 ALTER TABLE `message` DISABLE KEYS */;
INSERT INTO `message` VALUES (1,15,'2010-07-29','16:50:50','info','mon premier message'),(2,15,'0000-00-00','16:52:35','INFO','ET BLABALBLA');
/*!40000 ALTER TABLE `message` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `component_instance`
--

DROP TABLE IF EXISTS `component_instance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `component_instance` (
  `component_instance_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `cluster_id` int(8) unsigned NOT NULL,
  `component_id` int(8) unsigned NOT NULL,
  `component_template_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`component_instance_id`),
  KEY `fk_component_instance_1` (`cluster_id`),
  KEY `fk_component_instance_2` (`component_template_id`),
  KEY `fk_component_instance_3` (`component_id`),
  CONSTRAINT `fk_component_instance_1` FOREIGN KEY (`cluster_id`) REFERENCES `cluster` (`cluster_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_component_instance_2` FOREIGN KEY (`component_template_id`) REFERENCES `component_template` (`component_template_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_component_instance_3` FOREIGN KEY (`component_id`) REFERENCES `component` (`component_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `component_instance`
--

LOCK TABLES `component_instance` WRITE;
/*!40000 ALTER TABLE `component_instance` DISABLE KEYS */;
INSERT INTO `component_instance` VALUES (1,1,1,NULL),(2,1,2,1),(3,1,3,NULL);
/*!40000 ALTER TABLE `component_instance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `openiscsi2`
--

DROP TABLE IF EXISTS `openiscsi2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `openiscsi2` (
  `openiscsi2_id` int(8) NOT NULL,
  `component_instance_id` int(8) DEFAULT NULL,
  `openiscsi2_target` char(64) NOT NULL,
  `openiscsi2_server` char(32) NOT NULL,
  `openiscsi2_port` int(4) DEFAULT NULL,
  PRIMARY KEY (`openiscsi2_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `openiscsi2`
--

LOCK TABLES `openiscsi2` WRITE;
/*!40000 ALTER TABLE `openiscsi2` DISABLE KEYS */;
/*!40000 ALTER TABLE `openiscsi2` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `component_template_attr`
--

DROP TABLE IF EXISTS `component_template_attr`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `component_template_attr` (
  `template_component_id` int(8) unsigned NOT NULL,
  `template_component_attr_file` varchar(45) NOT NULL,
  `component_template_attr_field` varchar(45) NOT NULL,
  `component_template_attr_type` varchar(45) NOT NULL,
  PRIMARY KEY (`template_component_id`),
  KEY `fk_component_template_attr_1` (`template_component_id`),
  CONSTRAINT `fk_component_template_attr_1` FOREIGN KEY (`template_component_id`) REFERENCES `component_template` (`component_template_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `component_template_attr`
--

LOCK TABLES `component_template_attr` WRITE;
/*!40000 ALTER TABLE `component_template_attr` DISABLE KEYS */;
/*!40000 ALTER TABLE `component_template_attr` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `component_instance_entity`
--

DROP TABLE IF EXISTS `component_instance_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `component_instance_entity` (
  `entity_id` int(8) unsigned NOT NULL,
  `component_instance_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`entity_id`,`component_instance_id`),
  KEY `fk_component_instance_entity_1` (`entity_id`),
  KEY `fk_component_instance_entity_2` (`component_instance_id`),
  CONSTRAINT `fk_component_instance_entity_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_component_instance_entity_2` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `component_instance_entity`
--

LOCK TABLES `component_instance_entity` WRITE;
/*!40000 ALTER TABLE `component_instance_entity` DISABLE KEYS */;
INSERT INTO `component_instance_entity` VALUES (188,1),(189,2),(190,3);
/*!40000 ALTER TABLE `component_instance_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `component_installed`
--

DROP TABLE IF EXISTS `component_installed`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `component_installed` (
  `component_id` int(8) unsigned NOT NULL,
  `systemimage_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`component_id`,`systemimage_id`),
  KEY `fk_component_installed_1` (`component_id`),
  KEY `fk_component_installed_2` (`systemimage_id`),
  CONSTRAINT `fk_component_installed_1` FOREIGN KEY (`component_id`) REFERENCES `component` (`component_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_component_installed_2` FOREIGN KEY (`systemimage_id`) REFERENCES `systemimage` (`systemimage_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `component_installed`
--

LOCK TABLES `component_installed` WRITE;
/*!40000 ALTER TABLE `component_installed` DISABLE KEYS */;
INSERT INTO `component_installed` VALUES (1,1),(2,1),(3,1);
/*!40000 ALTER TABLE `component_installed` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `operation`
--

DROP TABLE IF EXISTS `operation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `operation` (
  `operation_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `type` char(64) NOT NULL,
  `user_id` int(8) unsigned NOT NULL,
  `priority` int(2) unsigned NOT NULL,
  `creation_date` date NOT NULL,
  `creation_time` time NOT NULL,
  `execution_rank` int(8) unsigned NOT NULL,
  PRIMARY KEY (`operation_id`),
  UNIQUE KEY `execution_rank_UNIQUE` (`execution_rank`),
  KEY `fk_operation_queue_1` (`user_id`),
  CONSTRAINT `fk_operation_queue_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `operation`
--

LOCK TABLES `operation` WRITE;
/*!40000 ALTER TABLE `operation` DISABLE KEYS */;
INSERT INTO `operation` VALUES (17,'AddMotherboard',16,100,'0000-00-00','00:00:00',1),(18,'AddMotherboard',16,200,'0000-00-00','00:00:00',2);
/*!40000 ALTER TABLE `operation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `iscsitarget1_lun`
--

DROP TABLE IF EXISTS `iscsitarget1_lun`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `iscsitarget1_lun` (
  `iscsitarget1_target_id` int(8) NOT NULL,
  `iscsitarget1_lun_id` int(8) NOT NULL AUTO_INCREMENT,
  `iscsitarget1_lun_number` int(8) NOT NULL,
  `iscsitarget1_lun_device` char(64) NOT NULL,
  `iscsitarget1_lun_typeio` char(32) NOT NULL,
  `iscsitarget1_lun_iomode` char(16) NOT NULL,
  PRIMARY KEY (`iscsitarget1_lun_id`),
  KEY `fk_iscsitarget1_lun_1` (`iscsitarget1_target_id`),
  CONSTRAINT `fk_iscsitarget1_lun_1` FOREIGN KEY (`iscsitarget1_target_id`) REFERENCES `iscsitarget1_target` (`iscsitarget1_target_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `iscsitarget1_lun`
--

LOCK TABLES `iscsitarget1_lun` WRITE;
/*!40000 ALTER TABLE `iscsitarget1_lun` DISABLE KEYS */;
/*!40000 ALTER TABLE `iscsitarget1_lun` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `operation_entity`
--

DROP TABLE IF EXISTS `operation_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `operation_entity` (
  `entity_id` int(8) unsigned NOT NULL,
  `operation_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`entity_id`,`operation_id`),
  UNIQUE KEY `fk_operation_entity_1` (`entity_id`),
  UNIQUE KEY `fk_operation_entity_2` (`operation_id`),
  CONSTRAINT `fk_operation_entity_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_operation_entity_2` FOREIGN KEY (`operation_id`) REFERENCES `operation` (`operation_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `operation_entity`
--

LOCK TABLES `operation_entity` WRITE;
/*!40000 ALTER TABLE `operation_entity` DISABLE KEYS */;
/*!40000 ALTER TABLE `operation_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `apache2`
--

DROP TABLE IF EXISTS `apache2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `apache2` (
  `component_instance_id` int(8) unsigned NOT NULL,
  `servername` char(32) NOT NULL,
  PRIMARY KEY (`component_instance_id`),
  KEY `fk_apache2_1` (`component_instance_id`),
  CONSTRAINT `fk_apache2_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `apache2`
--

LOCK TABLES `apache2` WRITE;
/*!40000 ALTER TABLE `apache2` DISABLE KEYS */;
/*!40000 ALTER TABLE `apache2` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `publicip`
--

DROP TABLE IF EXISTS `publicip`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `publicip` (
  `publicip_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `ip_address` char(1) NOT NULL,
  `ip_mask` char(1) NOT NULL,
  `gateway` char(1) DEFAULT NULL,
  `cluster_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`publicip_id`),
  KEY `fk_network_1` (`cluster_id`),
  CONSTRAINT `fk_network_1` FOREIGN KEY (`cluster_id`) REFERENCES `cluster` (`cluster_id`) ON DELETE SET NULL ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `publicip`
--

LOCK TABLES `publicip` WRITE;
/*!40000 ALTER TABLE `publicip` DISABLE KEYS */;
INSERT INTO `publicip` VALUES (1,'1','2',NULL,1);
/*!40000 ALTER TABLE `publicip` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `node`
--

DROP TABLE IF EXISTS `node`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `node` (
  `node_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `cluster_id` int(8) unsigned NOT NULL,
  `motherboard_id` int(8) unsigned NOT NULL,
  `master_node` int(1) unsigned DEFAULT NULL,
  PRIMARY KEY (`node_id`),
  KEY `cluster_id` (`cluster_id`,`motherboard_id`),
  KEY `fk_node_1` (`cluster_id`),
  KEY `fk_node_2` (`motherboard_id`),
  CONSTRAINT `fk_node_1` FOREIGN KEY (`cluster_id`) REFERENCES `cluster` (`cluster_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_node_2` FOREIGN KEY (`motherboard_id`) REFERENCES `motherboard` (`motherboard_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `node`
--

LOCK TABLES `node` WRITE;
/*!40000 ALTER TABLE `node` DISABLE KEYS */;
INSERT INTO `node` VALUES (1,1,1,1);
/*!40000 ALTER TABLE `node` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cluster_entity`
--

DROP TABLE IF EXISTS `cluster_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cluster_entity` (
  `entity_id` int(8) unsigned NOT NULL,
  `cluster_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`entity_id`,`cluster_id`),
  KEY `fk_cluster_entity_1` (`entity_id`),
  KEY `fk_cluster_entity_2` (`cluster_id`),
  CONSTRAINT `fk_cluster_entity_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_cluster_entity_2` FOREIGN KEY (`cluster_id`) REFERENCES `cluster` (`cluster_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cluster_entity`
--

LOCK TABLES `cluster_entity` WRITE;
/*!40000 ALTER TABLE `cluster_entity` DISABLE KEYS */;
INSERT INTO `cluster_entity` VALUES (187,1);
/*!40000 ALTER TABLE `cluster_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `component`
--

DROP TABLE IF EXISTS `component`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `component` (
  `component_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `component_name` varchar(45) NOT NULL,
  `component_version` varchar(45) NOT NULL,
  `component_category` varchar(45) NOT NULL,
  PRIMARY KEY (`component_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `component`
--

LOCK TABLES `component` WRITE;
/*!40000 ALTER TABLE `component` DISABLE KEYS */;
INSERT INTO `component` VALUES (1,'Lvm','2','Storage'),(2,'Apache','2','Webserver'),(3,'Iscsitarget','1','Export'),(4,'Openiscsi','2','ExportClient');
/*!40000 ALTER TABLE `component` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `groups_entity`
--

DROP TABLE IF EXISTS `groups_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `groups_entity` (
  `entity_id` int(8) unsigned NOT NULL,
  `groups_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`entity_id`,`groups_id`),
  UNIQUE KEY `fk_groups_entity_1` (`entity_id`),
  UNIQUE KEY `fk_groups_entity_2` (`groups_id`),
  CONSTRAINT `fk_groups_entity_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_groups_entity_2` FOREIGN KEY (`groups_id`) REFERENCES `groups` (`groups_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `groups_entity`
--

LOCK TABLES `groups_entity` WRITE;
/*!40000 ALTER TABLE `groups_entity` DISABLE KEYS */;
INSERT INTO `groups_entity` VALUES (121,35),(122,36),(123,37),(124,38),(125,39),(126,40),(127,41),(128,42),(129,43),(130,44);
/*!40000 ALTER TABLE `groups_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `iscsitarget1_target`
--

DROP TABLE IF EXISTS `iscsitarget1_target`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `iscsitarget1_target` (
  `component_instance_id` int(8) unsigned NOT NULL,
  `iscsitarget1_target_id` int(8) NOT NULL AUTO_INCREMENT,
  `iscsitarget1_target_name` char(128) NOT NULL,
  `mountpoint` char(64) DEFAULT NULL,
  `mount_option` char(32) DEFAULT NULL,
  PRIMARY KEY (`iscsitarget1_target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `iscsitarget1_target`
--

LOCK TABLES `iscsitarget1_target` WRITE;
/*!40000 ALTER TABLE `iscsitarget1_target` DISABLE KEYS */;
/*!40000 ALTER TABLE `iscsitarget1_target` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ingroups`
--

DROP TABLE IF EXISTS `ingroups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ingroups` (
  `groups_id` int(8) unsigned NOT NULL,
  `entity_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`groups_id`,`entity_id`),
  KEY `fk_grouping_1` (`entity_id`),
  KEY `fk_grouping_2` (`groups_id`),
  CONSTRAINT `fk_grouping_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_grouping_2` FOREIGN KEY (`groups_id`) REFERENCES `groups` (`groups_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ingroups`
--

LOCK TABLES `ingroups` WRITE;
/*!40000 ALTER TABLE `ingroups` DISABLE KEYS */;
INSERT INTO `ingroups` VALUES (44,131),(35,132),(44,132),(35,133),(44,133),(35,134),(35,179),(35,180),(35,181);
/*!40000 ALTER TABLE `ingroups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `operation_parameter`
--

DROP TABLE IF EXISTS `operation_parameter`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `operation_parameter` (
  `operation_param_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `name` char(64) NOT NULL,
  `value` char(255) NOT NULL,
  `operation_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`operation_param_id`),
  KEY `fk_operation_parameter_1` (`operation_id`),
  CONSTRAINT `fk_operation_parameter_1` FOREIGN KEY (`operation_id`) REFERENCES `operation` (`operation_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `operation_parameter`
--

LOCK TABLES `operation_parameter` WRITE;
/*!40000 ALTER TABLE `operation_parameter` DISABLE KEYS */;
INSERT INTO `operation_parameter` VALUES (49,'motherboard_serial_number','Test sn',17),(50,'kernel_id','2',17),(51,'motherboard_mac_address','00:1c:c0:c0:1c:9a',17),(52,'motherboard_serial_number','Test2 sn',18),(53,'kernel_id','1',18),(54,'motherboard_mac_address','00:1c:c1:c1:c1:c1',18);
/*!40000 ALTER TABLE `operation_parameter` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user` (
  `user_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `user_login` char(32) NOT NULL,
  `user_password` char(32) NOT NULL,
  `user_firstname` char(64) DEFAULT NULL,
  `user_lastname` char(64) DEFAULT NULL,
  `user_email` char(255) DEFAULT NULL,
  `user_creationdate` date DEFAULT NULL,
  `user_lastaccess` datetime DEFAULT NULL,
  `user_desc` char(255) DEFAULT 'Note concerning this user',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `user_login` (`user_login`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (14,'executer','executer','executer','executer',NULL,'2010-07-22',NULL,'executer'),(15,'thom','pass','Thomas','MANNI','thomas.manni@hederatech.com','2010-07-22',NULL,''),(16,'xebech','pass','Antoine','CASTAING','antoine.castaing@hederatech.com','2010-07-22',NULL,''),(17,'tortue','pass','Sylvain','YVON-PALIOT','sylvain.yvon-paliot@hederatech.com','2010-07-22',NULL,''),(18,'titi','pass','titi','titi','titi@somewhere.com','2010-07-25',NULL,'Note concerning this user'),(19,'tata','pass','tata','tata','tata@somewhere.com','2010-07-25',NULL,'Note concerning this user'),(20,'toto','pass','toto','toto','toto@somewhere.com','2010-07-25',NULL,'Note concerning this user');
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `groups`
--

DROP TABLE IF EXISTS `groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `groups` (
  `groups_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `groups_name` char(32) NOT NULL,
  `groups_desc` char(255) DEFAULT NULL,
  `groups_system` int(1) unsigned NOT NULL,
  PRIMARY KEY (`groups_id`),
  UNIQUE KEY `groups_name` (`groups_name`)
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `groups`
--

LOCK TABLES `groups` WRITE;
/*!40000 ALTER TABLE `groups` DISABLE KEYS */;
INSERT INTO `groups` VALUES (35,'User','User master group',1),(36,'Processortemplate','Processortemplate master group',1),(37,'Motherboardtemplate','Motherboardtemplate master group',1),(38,'Motherboard','Motherboard master group',1),(39,'Cluster','Cluster master group',1),(40,'Distribution','Distribution master group',1),(41,'Kernel','Kernel master group',1),(42,'Systemimage','Systemimage master group',1),(43,'Operationtype','Operationtype master group',1),(44,'admin','for administration tasks',1);
/*!40000 ALTER TABLE `groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `motherboarddetails`
--

DROP TABLE IF EXISTS `motherboarddetails`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `motherboarddetails` (
  `motherboard_id` int(8) unsigned NOT NULL,
  `name` char(32) NOT NULL,
  `value` char(255) DEFAULT NULL,
  PRIMARY KEY (`motherboard_id`,`name`),
  KEY `fk_motherboarddetails_1` (`motherboard_id`),
  CONSTRAINT `fk_motherboarddetails_1` FOREIGN KEY (`motherboard_id`) REFERENCES `motherboard` (`motherboard_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `motherboarddetails`
--

LOCK TABLES `motherboarddetails` WRITE;
/*!40000 ALTER TABLE `motherboarddetails` DISABLE KEYS */;
/*!40000 ALTER TABLE `motherboarddetails` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `motherboard_model_entity`
--

DROP TABLE IF EXISTS `motherboard_model_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `motherboard_model_entity` (
  `entity_id` int(8) unsigned NOT NULL,
  `motherboard_model_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`entity_id`,`motherboard_model_id`),
  KEY `fk_motherboard_model_entity_1` (`entity_id`),
  KEY `fk_motherboard_model_entity_2` (`motherboard_model_id`),
  CONSTRAINT `fk_motherboard_model_entity_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_motherboard_model_entity_2` FOREIGN KEY (`motherboard_model_id`) REFERENCES `motherboard_model` (`motherboard_model_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `motherboard_model_entity`
--

LOCK TABLES `motherboard_model_entity` WRITE;
/*!40000 ALTER TABLE `motherboard_model_entity` DISABLE KEYS */;
INSERT INTO `motherboard_model_entity` VALUES (182,1);
/*!40000 ALTER TABLE `motherboard_model_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `processor_model_entity`
--

DROP TABLE IF EXISTS `processor_model_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `processor_model_entity` (
  `entity_id` int(8) unsigned NOT NULL,
  `processor_model_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`entity_id`,`processor_model_id`),
  KEY `fk_processor_model_entity_1` (`entity_id`),
  KEY `fk_processor_model_entity_2` (`processor_model_id`),
  CONSTRAINT `fk_processor_model_entity_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_processor_model_entity_2` FOREIGN KEY (`processor_model_id`) REFERENCES `processor_model` (`processor_model_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `processor_model_entity`
--

LOCK TABLES `processor_model_entity` WRITE;
/*!40000 ALTER TABLE `processor_model_entity` DISABLE KEYS */;
INSERT INTO `processor_model_entity` VALUES (184,1);
/*!40000 ALTER TABLE `processor_model_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lvm2_pv`
--

DROP TABLE IF EXISTS `lvm2_pv`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lvm2_pv` (
  `lvm2_vg_id` int(8) unsigned NOT NULL,
  `lvm2_pv_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `lvm2_pv_name` char(64) NOT NULL,
  PRIMARY KEY (`lvm2_pv_id`),
  KEY `fk_lvm2_pv_1` (`lvm2_vg_id`),
  CONSTRAINT `fk_lvm2_pv_1` FOREIGN KEY (`lvm2_vg_id`) REFERENCES `lvm2_vg` (`lvm2_vg_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lvm2_pv`
--

LOCK TABLES `lvm2_pv` WRITE;
/*!40000 ALTER TABLE `lvm2_pv` DISABLE KEYS */;
INSERT INTO `lvm2_pv` VALUES (1,1,'/dev/sda4');
/*!40000 ALTER TABLE `lvm2_pv` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `component_template`
--

DROP TABLE IF EXISTS `component_template`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `component_template` (
  `component_template_id` int(8) unsigned NOT NULL,
  `component_template_name` varchar(45) NOT NULL,
  `component_template_directory` varchar(45) NOT NULL,
  PRIMARY KEY (`component_template_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `component_template`
--

LOCK TABLES `component_template` WRITE;
/*!40000 ALTER TABLE `component_template` DISABLE KEYS */;
INSERT INTO `component_template` VALUES (1,'defaultapache','/templates/defaultapache');
/*!40000 ALTER TABLE `component_template` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `route`
--

DROP TABLE IF EXISTS `route`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `route` (
  `route_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `publicip_id` int(8) unsigned NOT NULL,
  `ip_destination` char(1) NOT NULL,
  `gateway` char(1) DEFAULT NULL,
  PRIMARY KEY (`route_id`),
  KEY `fk_route_1` (`publicip_id`),
  CONSTRAINT `fk_route_1` FOREIGN KEY (`publicip_id`) REFERENCES `publicip` (`publicip_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `route`
--

LOCK TABLES `route` WRITE;
/*!40000 ALTER TABLE `route` DISABLE KEYS */;
/*!40000 ALTER TABLE `route` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `operationtype_entity`
--

DROP TABLE IF EXISTS `operationtype_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `operationtype_entity` (
  `entity_id` int(8) unsigned NOT NULL,
  `operationtype_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`entity_id`,`operationtype_id`),
  KEY `fk_operationtype_entity_1` (`entity_id`),
  KEY `fk_operationtype_entity_2` (`operationtype_id`),
  CONSTRAINT `fk_operationtype_entity_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_operationtype_entity_2` FOREIGN KEY (`operationtype_id`) REFERENCES `operationtype` (`operationtype_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `operationtype_entity`
--

LOCK TABLES `operationtype_entity` WRITE;
/*!40000 ALTER TABLE `operationtype_entity` DISABLE KEYS */;
/*!40000 ALTER TABLE `operationtype_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `entityright`
--

DROP TABLE IF EXISTS `entityright`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `entityright` (
  `entityright_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `entityright_consumed_id` int(8) unsigned NOT NULL,
  `entityright_consumer_id` int(8) unsigned NOT NULL,
  `entityright_rights` int(1) unsigned NOT NULL,
  PRIMARY KEY (`entityright_id`),
  KEY `fk_entityright_1` (`entityright_consumed_id`),
  KEY `fk_entityright_2` (`entityright_consumer_id`),
  CONSTRAINT `fk_entityright_1` FOREIGN KEY (`entityright_consumed_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_entityright_2` FOREIGN KEY (`entityright_consumer_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `entityright`
--

LOCK TABLES `entityright` WRITE;
/*!40000 ALTER TABLE `entityright` DISABLE KEYS */;
INSERT INTO `entityright` VALUES (2,128,121,2),(3,121,121,2),(4,121,121,2),(6,121,130,7),(7,129,130,1),(8,129,121,2),(16,121,180,4);
/*!40000 ALTER TABLE `entityright` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `message_entity`
--

DROP TABLE IF EXISTS `message_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `message_entity` (
  `entity_id` int(8) unsigned NOT NULL,
  `message_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`entity_id`,`message_id`),
  KEY `fk_message_entity_1` (`entity_id`),
  KEY `fk_message_entity_2` (`message_id`),
  CONSTRAINT `fk_message_entity_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_message_entity_2` FOREIGN KEY (`message_id`) REFERENCES `message` (`message_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `message_entity`
--

LOCK TABLES `message_entity` WRITE;
/*!40000 ALTER TABLE `message_entity` DISABLE KEYS */;
/*!40000 ALTER TABLE `message_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `kernel_entity`
--

DROP TABLE IF EXISTS `kernel_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kernel_entity` (
  `entity_id` int(8) unsigned NOT NULL,
  `kernel_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`entity_id`,`kernel_id`),
  UNIQUE KEY `fk_kernel_entity_1` (`entity_id`),
  UNIQUE KEY `fk_kernel_entity_2` (`kernel_id`),
  CONSTRAINT `fk_kernel_entity_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_kernel_entity_2` FOREIGN KEY (`kernel_id`) REFERENCES `kernel` (`kernel_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `kernel_entity`
--

LOCK TABLES `kernel_entity` WRITE;
/*!40000 ALTER TABLE `kernel_entity` DISABLE KEYS */;
INSERT INTO `kernel_entity` VALUES (183,1);
/*!40000 ALTER TABLE `kernel_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `systemimage_entity`
--

DROP TABLE IF EXISTS `systemimage_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `systemimage_entity` (
  `entity_id` int(8) unsigned NOT NULL,
  `systemimage_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`entity_id`,`systemimage_id`),
  UNIQUE KEY `fk_systemimage_entity_1` (`entity_id`),
  UNIQUE KEY `fk_systemimage_entity_2` (`systemimage_id`),
  CONSTRAINT `fk_systemimage_entity_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT `fk_systemimage_entity_2` FOREIGN KEY (`systemimage_id`) REFERENCES `systemimage` (`systemimage_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `systemimage_entity`
--

LOCK TABLES `systemimage_entity` WRITE;
/*!40000 ALTER TABLE `systemimage_entity` DISABLE KEYS */;
INSERT INTO `systemimage_entity` VALUES (186,1);
/*!40000 ALTER TABLE `systemimage_entity` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `distribution`
--

DROP TABLE IF EXISTS `distribution`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `distribution` (
  `distribution_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `distribution_name` char(64) NOT NULL,
  `distribution_version` char(32) NOT NULL,
  `distribution_desc` char(255) DEFAULT NULL,
  `etc_device_id` int(8) unsigned NOT NULL,
  `root_device_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`distribution_id`),
  UNIQUE KEY `distribution_name` (`distribution_name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `distribution`
--

LOCK TABLES `distribution` WRITE;
/*!40000 ALTER TABLE `distribution` DISABLE KEYS */;
INSERT INTO `distribution` VALUES (1,'Debian','5.0','First Debian',1,0);
/*!40000 ALTER TABLE `distribution` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lvm2_lv`
--

DROP TABLE IF EXISTS `lvm2_lv`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lvm2_lv` (
  `lvm2_vg_id` int(8) unsigned NOT NULL,
  `lvm2_lv_name` char(32) NOT NULL,
  `lvm2_lv_freespace` int(8) NOT NULL,
  `lvm2_lv_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `lvm2_lv_size` int(8) unsigned NOT NULL,
  `lvm2_lv_filesystem` char(10) NOT NULL,
  PRIMARY KEY (`lvm2_lv_id`),
  KEY `fk_lvm2_lv_1` (`lvm2_vg_id`),
  CONSTRAINT `fk_lvm2_lv_1` FOREIGN KEY (`lvm2_vg_id`) REFERENCES `lvm2_vg` (`lvm2_vg_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lvm2_lv`
--

LOCK TABLES `lvm2_lv` WRITE;
/*!40000 ALTER TABLE `lvm2_lv` DISABLE KEYS */;
/*!40000 ALTER TABLE `lvm2_lv` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lvm2_vg`
--

DROP TABLE IF EXISTS `lvm2_vg`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lvm2_vg` (
  `component_instance_id` int(8) unsigned NOT NULL,
  `lvm2_vg_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `lvm2_vg_name` char(32) NOT NULL,
  `lvm2_vg_freespace` int(8) NOT NULL,
  `lvm2_vg_size` int(8) NOT NULL,
  PRIMARY KEY (`lvm2_vg_id`),
  KEY `fk_lvm2_vg_1` (`component_instance_id`),
  CONSTRAINT `fk_lvm2_vg_1` FOREIGN KEY (`component_instance_id`) REFERENCES `component_instance` (`component_instance_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lvm2_vg`
--

LOCK TABLES `lvm2_vg` WRITE;
/*!40000 ALTER TABLE `lvm2_vg` DISABLE KEYS */;
INSERT INTO `lvm2_vg` VALUES (1,1,'vg1',65610,134190);
/*!40000 ALTER TABLE `lvm2_vg` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_entity`
--

DROP TABLE IF EXISTS `user_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_entity` (
  `entity_id` int(8) unsigned NOT NULL,
  `user_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`entity_id`,`user_id`),
  UNIQUE KEY `fk_user_entity_1` (`entity_id`),
  UNIQUE KEY `fk_user_entity_2` (`user_id`),
  CONSTRAINT `fk_user_entity_1` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_user_entity_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

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

-- Dump completed on 2010-08-12 12:37:58
