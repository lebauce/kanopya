--   Copyright © 2011 Hedera Technology SAS
--   This program is free software: you can redistribute it and/or modify
--   it under the terms of the GNU Affero General Public License as
--   published by the Free Software Foundation, either version 3 of the
--   License, or (at your option) any later version.
--
--   This program is distributed in the hope that it will be useful,
--   but WITHOUT ANY WARRANTY; without even the implied warranty of
--   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--   GNU Affero General Public License for more details.
--
--   You should have received a copy of the GNU Affero General Public License
--   along with this program.  If not, see <http://www.gnu.org/licenses/>.

DROP DATABASE IF EXISTS `kanopya`;

CREATE DATABASE `kanopya`;
USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `class_type`

CREATE TABLE `class_type` (
  `class_type_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `class_type` TEXT NOT NULL,
  PRIMARY KEY (`class_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `entity_comment`
-- EntityComment class

CREATE TABLE `entity_comment` (
  `entity_comment_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `entity_comment` char(255) DEFAULT NULL,
  PRIMARY KEY (`entity_comment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `entity`
-- Entity class

CREATE TABLE `entity` (
  `entity_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `class_type_id` int(8) unsigned NOT NULL,
  `entity_comment_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`entity_id`),
  KEY (`class_type_id`),
  FOREIGN KEY (`entity_comment_id`) REFERENCES `entity_comment` (`entity_comment_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (`class_type_id`) REFERENCES `class_type` (`class_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `entity_lock`
-- EntityComment class

CREATE TABLE `entity_lock` (
  `entity_lock_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `entity_id` int(8) unsigned NOT NULL,
  `workflow_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`entity_lock_id`),
  UNIQUE KEY (`entity_id`),
  FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`workflow_id`),
  FOREIGN KEY (`workflow_id`) REFERENCES `workflow` (`workflow_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `service_provider`
-- Entity::ServiceProvider class

CREATE TABLE `service_provider` (
  `service_provider_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`service_provider_id`),
  FOREIGN KEY (`service_provider_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `inside`
-- Entity::ServiceProvider::Inside class

CREATE TABLE `inside` (
  `inside_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`inside_id`),
  FOREIGN KEY (`inside_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `cluster`
-- Entity::ServiceProvider::Inside::Cluster class

CREATE TABLE `cluster` (
  `cluster_id` int(8) unsigned NOT NULL,
  `cluster_name` char(32) NOT NULL,
  `cluster_desc` char(255) DEFAULT NULL,
  `cluster_type` int(1) unsigned DEFAULT NULL,
  `cluster_min_node` int(2) unsigned NOT NULL,
  `cluster_max_node` int(2) unsigned NOT NULL,
  `cluster_priority` int(1) unsigned NOT NULL,
  `cluster_boot_policy` char(32) NOT NULL,
  `cluster_si_shared` int(1) unsigned NOT NULL,
  `cluster_si_persistent` int(1) unsigned NOT NULL DEFAULT 0,
  `cluster_domainname` char(64) NOT NULL,
  `cluster_nameserver1` char(15) NOT NULL,
  `cluster_nameserver2` char(15) NOT NULL,
  `cluster_state` char(32) NOT NULL DEFAULT 'down:0',
  `cluster_prev_state` char(32),
  `cluster_basehostname` char(64) NOT NULL,
  `active` int(1) unsigned NOT NULL,
  `user_id` int(8) unsigned NOT NULL,
  `kernel_id` int(8) unsigned DEFAULT NULL,
  `masterimage_id` int(8) unsigned DEFAULT NULL,
  `service_template_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`cluster_id`),
  UNIQUE KEY (`cluster_name`),
  FOREIGN KEY (`cluster_id`) REFERENCES `inside` (`inside_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`kernel_id`),
  FOREIGN KEY (`kernel_id`) REFERENCES `kernel` (`kernel_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`masterimage_id`),
  FOREIGN KEY (`masterimage_id`) REFERENCES `masterimage` (`masterimage_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`service_template_id`),
  FOREIGN KEY (`service_template_id`) REFERENCES `service_template` (`service_template_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `service_provider_manager`

CREATE TABLE `service_provider_manager` (
  `service_provider_manager_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `service_provider_id` int(8) unsigned NOT NULL,
  `manager_type` char(64) NOT NULL,
  `manager_id` int(8) unsigned NOT NULL,
  `param_preset_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`service_provider_manager_id`),
  FOREIGN KEY (`service_provider_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`param_preset_id`),
  FOREIGN KEY (`param_preset_id`) REFERENCES `param_preset` (`param_preset_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Table structure for table `server`
-- Entity::ServiceProvider::Inside::Server class

CREATE TABLE `server` (
  `server_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`server_id`),
  FOREIGN KEY (`server_id`) REFERENCES `inside` (`inside_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `outside`
-- Entity::ServiceProvider::Outside class

CREATE TABLE `outside` (
  `outside_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`outside_id`),
  FOREIGN KEY (`outside_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `netapp`
-- Entity::ServiceProvider::Outside::Netapp class

CREATE TABLE `netapp` (
  `netapp_id` int(8) unsigned NOT NULL,
  `netapp_name` char(32) NOT NULL,
  `netapp_desc` char(255) NULL,
  `netapp_addr` char(15) NOT NULL,
  `netapp_login` char(32) NOT NULL,
  `netapp_passwd` char(32) NOT NULL,
  PRIMARY KEY (`netapp_id`),
  FOREIGN KEY (`netapp_id`) REFERENCES `outside` (`outside_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Table ucs for connector

CREATE TABLE `ucs_manager` (
  `ucs_manager_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`ucs_manager_id`),
  FOREIGN KEY (`ucs_manager_id`) REFERENCES `connector` (`connector_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for tables netapp_lun_manager (connector)
-- Entity::Connector::NetappLunManager class

CREATE TABLE `netapp_lun_manager` (
    `netapp_lun_manager_id` int(8) unsigned NOT NULL,
    PRIMARY KEY (`netapp_lun_manager_id`),
    FOREIGN KEY (`netapp_lun_manager_id`) REFERENCES `connector` (`connector_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table netapp_volume_manager (connector)
-- Entity::Connector::NetappVolumeManager class

CREATE TABLE `netapp_volume_manager` (
    `netapp_volume_manager_id` int(8) unsigned NOT NULL,
    PRIMARY KEY (`netapp_volume_manager_id`),
    FOREIGN KEY (`netapp_volume_manager_id`) REFERENCES `connector` (`connector_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `ucs`
-- Entity::ServiceProvider::Outside::Ucs class

CREATE TABLE `unified_computing_system` (
  `ucs_id` int(8) unsigned NOT NULL,
  `ucs_name` char(32) NOT NULL,
  `ucs_desc` char(255) NULL,
  `ucs_addr` char(15) NOT NULL,
  `ucs_state` char(32) NOT NULL DEFAULT 'down:0',
  `ucs_login` char(32) NOT NULL,
  `ucs_passwd` char(32) NOT NULL,
  `ucs_ou` char(32) NULL,
  PRIMARY KEY (`ucs_id`),
  FOREIGN KEY (`ucs_id`) REFERENCES `outside` (`outside_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `kernel`
-- Entity::Kernel class

CREATE TABLE `kernel` (
  `kernel_id` int(8) unsigned NOT NULL,
  `kernel_name` char(64) NOT NULL,
  `kernel_version` char(32) NOT NULL,
  `kernel_desc` char(255) DEFAULT NULL,
  PRIMARY KEY (`kernel_id`),
  FOREIGN KEY (`kernel_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `processormodel`
-- Entity::Processormodel class

CREATE TABLE `processormodel` (
  `processormodel_id` int(8) unsigned NOT NULL,
  `processormodel_brand` char(64) NOT NULL,
  `processormodel_name` char(64) NOT NULL,
  `processormodel_core_num` int(2) unsigned NOT NULL,
  `processormodel_clock_speed` float unsigned NOT NULL,
  `processormodel_l2_cache` int(2) unsigned NOT NULL,
  `processormodel_max_tdp` int(2) unsigned NOT NULL,
  `processormodel_64bits` int(1) unsigned NOT NULL,
  `processormodel_virtsupport` int(1) unsigned NOT NULL,
  PRIMARY KEY (`processormodel_id`),
  FOREIGN KEY (`processormodel_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  UNIQUE KEY (`processormodel_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `powersupplycardmodel`
-- Entity::Powersupplycardmodel class

CREATE TABLE `powersupplycardmodel` (
  `powersupplycardmodel_id` int(8) unsigned NOT NULL,
  `powersupplycardmodel_brand` char(64) NOT NULL,
  `powersupplycardmodel_name` char(32) NOT NULL,
  `powersupplycardmodel_slotscount` int(2) unsigned NOT NULL,
  PRIMARY KEY (`powersupplycardmodel_id`),
  FOREIGN KEY (`powersupplycardmodel_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  UNIQUE KEY (`powersupplycardmodel_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `hostmodel`
-- Entity::Hostmodel class

CREATE TABLE `hostmodel` (
  `hostmodel_id` int(8) unsigned NOT NULL,
  `hostmodel_brand` char(64) NOT NULL,
  `hostmodel_name` char(64) NOT NULL,
  `hostmodel_chipset` char(64) NOT NULL,
  `hostmodel_processor_num` int(3) unsigned NOT NULL,
  `hostmodel_consumption` int(8) unsigned NOT NULL,
  `hostmodel_iface_num` int(3) unsigned NOT NULL,
  `hostmodel_ram_slot_num` int(3) unsigned NOT NULL,
  `hostmodel_ram_max` int(32) unsigned NOT NULL,
  `processormodel_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`hostmodel_id`),
  FOREIGN KEY (`hostmodel_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  UNIQUE KEY (`hostmodel_name`),
  KEY (`processormodel_id`),
  FOREIGN KEY (`processormodel_id`) REFERENCES `processormodel` (`processormodel_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `container`
-- Entity::Container class

CREATE TABLE `container` (
  `container_id` int(8) unsigned NOT NULL,
  `container_name` char(128) NOT NULL,
  `container_size` int(8) unsigned NOT NULL,
  `container_device` char(255) NOT NULL,
  `container_filesystem` char(32) NOT NULL,
  `container_freespace` int(8) unsigned NOT NULL,
  `disk_manager_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`container_id`),
  FOREIGN KEY (`container_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `lvm_container`
-- Entity::Container::LvmContainer class

CREATE TABLE `lvm_container` (
  `lvm_container_id` int(8) unsigned NOT NULL,
  `lv_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`lvm_container_id`),
  FOREIGN KEY (`lvm_container_id`) REFERENCES `container` (`container_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `file_container`
-- Entity::Container::FileContainer class

CREATE TABLE `file_container` (
  `file_container_id` int(8) unsigned NOT NULL,
  `container_access_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`file_container_id`),
  FOREIGN KEY (`file_container_id`) REFERENCES `container` (`container_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`container_access_id`),
  FOREIGN KEY (`container_access_id`) REFERENCES `container_access` (`container_access_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `netapp_aggregate`
-- Entity::NetappAggregate class

CREATE TABLE `netapp_aggregate` (
  `aggregate_id` int(8) unsigned NOT NULL,
  `name` char(255) NOT NULL,
  `netapp_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`aggregate_id`),
  FOREIGN KEY (`aggregate_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (`netapp_id`) REFERENCES `netapp` (`netapp_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `netapp_volume`
-- Entity::Container::NetAppVolume class

CREATE TABLE `netapp_volume` (
  `volume_id` int(8) unsigned NOT NULL,
  `aggregate_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`volume_id`),
  FOREIGN KEY (`volume_id`) REFERENCES `container` (`container_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (`aggregate_id`) REFERENCES `netapp_aggregate` (`aggregate_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `netapp_lun`
-- Entity::Container::NetAppLun class

CREATE TABLE `netapp_lun` (
  `lun_id` int(8) unsigned NOT NULL,
  `volume_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`lun_id`),
  FOREIGN KEY (`lun_id`) REFERENCES `container` (`container_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`volume_id`),
  FOREIGN KEY (`volume_id`) REFERENCES `netapp_volume` (`volume_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `container_access`
-- Entity::ContainerAccess class

CREATE TABLE `container_access` (
  `container_access_id` int(8) unsigned NOT NULL,
  `container_id` int(8) unsigned NOT NULL,
  `container_access_export` char(255) NOT NULL,
  `container_access_ip` char(15) NOT NULL,
  `container_access_port` int(8) NOT NULL,
  `device_connected` char(255) NOT NULL DEFAULT '',
  `partition_connected` char(255) NOT NULL DEFAULT '',
  `export_manager_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`container_access_id`),
  FOREIGN KEY (`container_access_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`container_id`),
  FOREIGN KEY (`container_id`) REFERENCES `container` (`container_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `file_container_access`
-- Entity::ContainerAccess::FileContainerAccess class

CREATE TABLE `file_container_access` (
  `file_container_access_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`file_container_access_id`),
  FOREIGN KEY (`file_container_access_id`) REFERENCES `container_access` (`container_access_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `iscsi_container_access`
-- Entity::ContainerAccess::IscsiContainerAccess class

CREATE TABLE `iscsi_container_access` (
  `iscsi_container_access_id` int(8) unsigned NOT NULL,
  `typeio` char(32) NOT NULL,
  `iomode` char(16) NOT NULL,
  `lun_name` char(255) NOT NULL,
  PRIMARY KEY (`iscsi_container_access_id`),
  FOREIGN KEY (`iscsi_container_access_id`) REFERENCES `container_access` (`container_access_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `nfs_container_access`
-- Entity::ContainerAccess::NfsContainerAccess class

CREATE TABLE `nfs_container_access` (
  `nfs_container_access_id` int(8) unsigned NOT NULL,
  `options` char(255) NOT NULL,
  PRIMARY KEY (`nfs_container_access_id`),
  FOREIGN KEY (`nfs_container_access_id`) REFERENCES `container_access` (`container_access_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for nfsd3_exportclient
--

CREATE TABLE `nfs_container_access_client` (
  `nfs_container_access_client_id` int(8) unsigned NOT NULL,
  `name` char(255) NOT NULL,
  `options` char(255) NOT NULL,
  `nfs_container_access_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`nfs_container_access_client_id`),
  FOREIGN KEY (`nfs_container_access_client_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (`nfs_container_access_id`) REFERENCES `nfs_container_access` (`nfs_container_access_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `host`
-- Entity::Host

CREATE TABLE `host` (
  `host_id` int(8) unsigned NOT NULL,
  `host_manager_id` int(8) unsigned NOT NULL,
  `hostmodel_id` int(8) unsigned NULL DEFAULT NULL,
  `processormodel_id` int(8) unsigned NULL DEFAULT NULL,
  `kernel_id` int(8) unsigned NOT NULL,
  `host_serial_number` char(64) NOT NULL,
  `host_powersupply_id` int(8) unsigned,
  `host_desc` char(255) DEFAULT NULL,
  `active` int(1) unsigned NOT NULL,
  `host_initiatorname` char(64) DEFAULT NULL,
  `host_ram` bigint unsigned DEFAULT NULL,
  `host_core` int(1) unsigned DEFAULT NULL,
  `host_hostname` char(32) DEFAULT NULL,
  `host_state` char(32) NOT NULL DEFAULT 'down:0',
  `host_prev_state` char(32),
  PRIMARY KEY (`host_id`),
  FOREIGN KEY (`host_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`hostmodel_id`),
  FOREIGN KEY (`hostmodel_id`) REFERENCES `hostmodel` (`hostmodel_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`processormodel_id`),
  FOREIGN KEY (`processormodel_id`) REFERENCES `processormodel` (`processormodel_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`kernel_id`),
  FOREIGN KEY (`kernel_id`) REFERENCES `kernel` (`kernel_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`host_powersupply_id`),
  FOREIGN KEY (`host_powersupply_id`) REFERENCES `powersupply` (`powersupply_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `iface`
--
CREATE TABLE `iface` (
  `iface_id` int(8) UNSIGNED NOT NULL,
  `iface_name` char(32) NOT NULL ,
  `iface_mac_addr` char(18) NOT NULL ,
  `iface_pxe` int(10) UNSIGNED NOT NULL,
  `host_id` int(8) UNSIGNED NOT NULL,
  `interface_id` int(8) UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`iface_id`),
  FOREIGN KEY (`iface_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  UNIQUE KEY (`iface_mac_addr`),
  UNIQUE KEY (`iface_name`,`host_id`),
  KEY (`host_id`),
  FOREIGN KEY (`host_id`) REFERENCES `host` (`host_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`interface_id`),
  FOREIGN KEY (`interface_id`) REFERENCES `interface` (`interface_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `harddisk`
--

CREATE TABLE `harddisk` (
  `harddisk_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `host_id` int(8) unsigned NOT NULL,
  `harddisk_device` char(32) NOT NULL,
  PRIMARY KEY (`harddisk_id`),
  KEY (`host_id`),
  FOREIGN KEY (`host_id`) REFERENCES `host` (`host_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `powersupplycard`
-- Entity::Powersupplycard class

CREATE TABLE `powersupplycard` (
  `powersupplycard_id` int(8) unsigned NOT NULL,
  `powersupplycard_name` char(64) NOT NULL,
  `ipv4_internal_id` int(8) unsigned DEFAULT NULL,
  `powersupplycardmodel_id` int(8) unsigned DEFAULT NULL,
  `powersupplycard_mac_address` char(32) NOT NULL,
  `active` int(1),
  PRIMARY KEY (`powersupplycard_id`),
  FOREIGN KEY (`powersupplycard_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`powersupplycardmodel_id`),
  FOREIGN KEY (`powersupplycardmodel_id`) REFERENCES `powersupplycardmodel` (`powersupplycardmodel_id`)  ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`ipv4_internal_id`),
  FOREIGN KEY (`ipv4_internal_id`) REFERENCES `ipv4_internal` (`ipv4_internal_id`)  ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `powersupply`
--

CREATE TABLE `powersupply` (
  `powersupply_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `powersupplycard_id` int(8) unsigned NOT NULL,
  `powersupplyport_number` int(8) unsigned NOT NULL,
  PRIMARY KEY (`powersupply_id`),
  KEY (`powersupplycard_id`),
  FOREIGN KEY (`powersupplycard_id`) REFERENCES `powersupplycard` (`powersupplycard_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `node`
--

CREATE TABLE `node` (
  `node_id` int(8) unsigned NOT NULL,
  `inside_id` int(8) unsigned NOT NULL,
  `host_id` int(8) unsigned NOT NULL,
  `master_node` int(1) unsigned DEFAULT NULL,
  `node_state` char(32),
  `node_prev_state` char(32),
  `node_number` int(8) unsigned NOT NULL,
  `systemimage_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`node_id`),
  UNIQUE KEY (`host_id`),
  FOREIGN KEY (`node_id`) REFERENCES `externalnode` (`externalnode_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (`host_id`) REFERENCES `host` (`host_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`inside_id`),
  FOREIGN KEY (`inside_id`) REFERENCES `inside` (`inside_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`systemimage_id`),
  FOREIGN KEY (`systemimage_id`) REFERENCES `systemimage` (`systemimage_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `operationtype`
--

CREATE TABLE `operationtype` (
  `operationtype_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `operationtype_name` char(64) DEFAULT NULL,
  PRIMARY KEY (`operationtype_id`),
  UNIQUE KEY (`operationtype_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `operation`
-- Operation class

CREATE TABLE `operation` (
  `operation_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `type` char(64) NOT NULL,
  `workflow_id` int(8) unsigned NOT NULL,
  `state` char(32) NOT NULL DEFAULT 'pending',
  `user_id` int(8) unsigned NOT NULL,
  `priority` int(2) unsigned NOT NULL,
  `creation_date` date NOT NULL,
  `creation_time` time NOT NULL,
  `hoped_execution_time` int(4) unsigned DEFAULT NULL,
  `execution_rank` int(8) unsigned NOT NULL,
  PRIMARY KEY (`operation_id`),
  UNIQUE KEY (`execution_rank`, `workflow_id`),
  KEY (`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`workflow_id`),
  FOREIGN KEY (`workflow_id`) REFERENCES `workflow` (`workflow_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`type`),
  FOREIGN KEY (`type`) REFERENCES `operationtype` (`operationtype_name`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `old_operation`
--

CREATE TABLE `old_operation` (
  `old_operation_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `type` char(64) NOT NULL,
  `workflow_id` int(8) unsigned NOT NULL,
  `user_id` int(8) unsigned NOT NULL,
  `priority` int(2) unsigned NOT NULL,
  `creation_date` date NOT NULL,
  `creation_time` time NOT NULL,
  `execution_date` date NOT NULL,
  `execution_time` time NOT NULL,
  `execution_status` char(32) NOT NULL,
  PRIMARY KEY (`old_operation_id`),
  KEY (`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`workflow_id`),
  FOREIGN KEY (`workflow_id`) REFERENCES `workflow` (`workflow_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`type`),
  FOREIGN KEY (`type`) REFERENCES `operationtype` (`operationtype_name`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `workflow_def_manager`
--

CREATE TABLE `workflow_def_manager` (
    `workflow_def_manager_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
    `manager_id` int(8) unsigned,
    `workflow_def_id` int(8) unsigned,
    PRIMARY KEY (`workflow_def_manager_id`),
    UNIQUE KEY (`manager_id`, `workflow_def_id`),
    CONSTRAINT FOREIGN KEY (`workflow_def_id`) REFERENCES `workflow_def` (`workflow_def_id`) ON DELETE CASCADE ON UPDATE NO ACTION
)   ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `operation_parameter`
--

CREATE TABLE `operation_parameter` (
  `operation_parameter_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `operation_id` int(8) unsigned NOT NULL,
  `name` char(64) NOT NULL,
  `value` char(255) NOT NULL,
  `tag` char(64) DEFAULT NULL,
  PRIMARY KEY (`operation_parameter_id`),
  UNIQUE KEY (`operation_id`, `name`, `tag`),
  KEY (`operation_id`),
  FOREIGN KEY (`operation_id`) REFERENCES `operation` (`operation_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `old_operation_parameter`
--

CREATE TABLE `old_operation_parameter` (
  `old_operation_parameter_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `old_operation_id` int(8) unsigned NOT NULL,
  `name` char(64) NOT NULL,
  `value` char(255) NOT NULL,
  `tag` char(64) DEFAULT NULL,
  PRIMARY KEY (`old_operation_parameter_id`),
  UNIQUE KEY (`old_operation_id`, `name`, `tag`),
  KEY (`old_operation_id`),
  FOREIGN KEY (`old_operation_id`) REFERENCES `old_operation` (`old_operation_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `workflow`
--

CREATE TABLE `workflow` (
  `workflow_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `workflow_name` char(64) DEFAULT NULL,
  `state` char(32) NOT NULL DEFAULT 'running',
  PRIMARY KEY (`workflow_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `workflow_def`
--

CREATE TABLE `workflow_def` (
  `workflow_def_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `workflow_def_name` char(64) DEFAULT NULL,
  `param_preset_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`workflow_def_id`),
  UNIQUE KEY (`workflow_def_name`),
  KEY (`param_preset_id`),
  FOREIGN KEY (`param_preset_id`) REFERENCES `param_preset` (`param_preset_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `workflow_step`
--

CREATE TABLE `workflow_step` (
  `workflow_step_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `workflow_def_id` int(8) unsigned NOT NULL,
  `operationtype_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`workflow_step_id`),
  KEY (`workflow_def_id`),
  FOREIGN KEY (`workflow_def_id`) REFERENCES `workflow_def` (`workflow_def_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`operationtype_id`),
  FOREIGN KEY (`operationtype_id`) REFERENCES `operationtype` (`operationtype_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `systemimage`
-- Entity::Systemimage class

CREATE TABLE `systemimage` (
  `systemimage_id` int(8) unsigned NOT NULL,
  `systemimage_name` char(32) NOT NULL,
  `systemimage_desc` char(255) DEFAULT NULL,
  `container_id` int(8) unsigned DEFAULT NULL,
  `active` int(1) unsigned NOT NULL,
  PRIMARY KEY (`systemimage_id`),
  FOREIGN KEY (`systemimage_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  UNIQUE KEY (`systemimage_name`),
  KEY (`container_id`),
  FOREIGN KEY (`container_id`) REFERENCES `container` (`container_id`) ON DELETE SET NULL ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- network tables


--
-- Table structure for table `poolip`
--
CREATE TABLE `poolip` (
  `poolip_id`      int(8) unsigned,
  `poolip_name`    char(32) NOT NULL,
  `poolip_addr`    char(15) NOT NULL,
  `poolip_mask`    smallint unsigned NOT NULL,
  `poolip_netmask` char(15) NOT NULL,
  `poolip_gateway` char(15) NOT NULL,
  PRIMARY KEY (`poolip_id`),
  FOREIGN KEY (`poolip_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  UNIQUE KEY (`poolip_name`),
  UNIQUE KEY (`poolip_addr`,`poolip_mask`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `ip`
--
CREATE TABLE `ip` (
  `ip_id`     int(8) unsigned AUTO_INCREMENT,
  `ip_addr`   char(15) NOT NULL,
  `poolip_id` int(8) unsigned NOT NULL,
  `iface_id`  int(8) unsigned NULL DEFAULT NULL,
  PRIMARY KEY (`ip_id`),
  UNIQUE KEY (`ip_addr`, `poolip_id`),
  KEY (`poolip_id`),
  FOREIGN KEY (`poolip_id`) REFERENCES `poolip` (`poolip_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`iface_id`),
  FOREIGN KEY (`iface_id`) REFERENCES `iface` (`iface_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `network`
--
CREATE TABLE `network` (
  `network_id`   int(8) unsigned,
  `network_name` char(32) NOT NULL,
  PRIMARY KEY (`network_id`),
  FOREIGN KEY (`network_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  UNIQUE KEY (`network_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `vlan`
--
CREATE TABLE `vlan` (
  `vlan_id`     int(8) unsigned,
  `vlan_number` int unsigned NOT NULL,
  PRIMARY KEY (`vlan_id`),
  FOREIGN KEY (`vlan_id`) REFERENCES `network` (`network_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  UNIQUE KEY (`vlan_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `interface_role`
--
CREATE TABLE `interface_role` (
  `interface_role_id`   int(8) unsigned AUTO_INCREMENT,
  `interface_role_name` char(32) NOT NULL,
  PRIMARY KEY (`interface_role_id`),
  FOREIGN KEY (`interface_role_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  UNIQUE KEY (`interface_role_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `interface`
--
CREATE TABLE `interface` (
  `interface_id`        int(8) unsigned,
  `interface_role_id`   int(8) unsigned NOT NULL,
  `service_provider_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`interface_id`),
  FOREIGN KEY (`interface_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`interface_role_id`),
  FOREIGN KEY (`interface_role_id`) REFERENCES `interface_role` (`interface_role_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`service_provider_id`),
  FOREIGN KEY (`service_provider_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `interface_network`
--
CREATE TABLE `interface_network` (
  `interface_id` int(8) unsigned NOT NULL,
  `network_id`   int(8) unsigned NOT NULL,
  PRIMARY KEY (`interface_id`, `network_id`),
  KEY (`interface_id`),
  FOREIGN KEY (`interface_id`) REFERENCES `interface` (`interface_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`network_id`),
  FOREIGN KEY (`network_id`) REFERENCES `network` (`network_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `network_poolip`
--
CREATE TABLE `network_poolip` (
  `network_id` int(8) unsigned NOT NULL,
  `poolip_id`  int(8) unsigned NOT NULL,
  PRIMARY KEY (`network_id`, `poolip_id`),
  KEY (`network_id`),
  FOREIGN KEY (`network_id`) REFERENCES `network` (`network_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`poolip_id`),
  FOREIGN KEY (`poolip_id`) REFERENCES `poolip` (`poolip_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



--
-- Table structure for table `ipv4_internal`
--

CREATE TABLE `ipv4_internal` (
  `ipv4_internal_id` int(8) UNSIGNED NOT NULL AUTO_INCREMENT ,
  `ipv4_internal_address` char(15) NOT NULL ,
  `ipv4_internal_mask` char(15) NOT NULL ,
  `ipv4_internal_default_gw` char(15) NULL ,
  PRIMARY KEY (`ipv4_internal_id`),
  UNIQUE KEY (`ipv4_internal_address`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `ipv4_dmz`
--

CREATE TABLE `ipv4_dmz` (
  `ipv4_dmz_id` int(8) UNSIGNED NOT NULL AUTO_INCREMENT ,
  `ipv4_dmz_address` char(15) NOT NULL ,
  `ipv4_dmz_mask` char(15) NOT NULL ,
  `tier_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`ipv4_dmz_id`),
  UNIQUE KEY (`ipv4_dmz_address`),
  KEY (`tier_id`),
  FOREIGN KEY (`tier_id`) REFERENCES `tier` (`tier_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `ipv4_public`
--

CREATE TABLE `ipv4_public` (
  `ipv4_public_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `ipv4_public_address` char(15) NOT NULL,
  `ipv4_public_mask` char(15) NOT NULL,
  `ipv4_public_default_gw` char(15) DEFAULT NULL,
  `cluster_id` int(8) unsigned DEFAULT NULL,
  `infrastructure_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`ipv4_public_id`),
  KEY (`cluster_id`),
  FOREIGN KEY (`cluster_id`) REFERENCES `cluster` (`cluster_id`) ON DELETE SET NULL ON UPDATE NO ACTION,
  KEY (`infrastructure_id`),
  FOREIGN KEY (`infrastructure_id`) REFERENCES `infrastructure` (`infrastructure_id`) ON DELETE SET NULL ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `ipv4_route`
--

CREATE TABLE `ipv4_route` (
  `ipv4_route_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `ipv4_route_destination` char(15) NOT NULL,
  `ipv4_route_gateway` char(15) DEFAULT NULL,
  `ipv4_route_context` char(10) NOT NULL, -- Context could be internal or public
  PRIMARY KEY (`ipv4_route_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `cluster_ipv4_route`
--

CREATE TABLE `cluster_ipv4_route` (
  `cluster_ipv4_route_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `cluster_id` int(8) unsigned NOT NULL,
  `ipv4_route_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`cluster_ipv4_route_id`),
  UNIQUE KEY (`cluster_id`,`ipv4_route_id`),
  KEY (`cluster_id`),
  FOREIGN KEY (`cluster_id`) REFERENCES `cluster` (`cluster_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`ipv4_route_id`),
  FOREIGN KEY (`ipv4_route_id`) REFERENCES `ipv4_route` (`ipv4_route_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `user`
-- Entity::User class

CREATE TABLE `user` (
  `user_id` int(8) unsigned NOT NULL,
  `user_system` int(1) unsigned NOT NULL DEFAULT 0,
  `user_login` char(32) NOT NULL,
  `user_password` char(32) NOT NULL,
  `user_firstname` char(64) DEFAULT NULL,
  `user_lastname` char(64) DEFAULT NULL,
  `user_email` char(255) DEFAULT NULL,
  `user_creationdate` date DEFAULT NULL,
  `user_lastaccess` datetime DEFAULT NULL,
  `user_desc` char(255) DEFAULT 'Note concerning this user',
  PRIMARY KEY (`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  UNIQUE KEY (`user_login`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `user_extension`

CREATE TABLE `user_extension` (
  `user_extension_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(8) unsigned NOT NULL,
  `user_extension_key` char(32) NOT NULL,
  `user_extension_value` char(255) NULL DEFAULT NULL,
  PRIMARY KEY (`user_extension_id`),
  UNIQUE KEY (`user_id`,`user_extension_key`),
  FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `profile`

CREATE TABLE `profile` (
  `profile_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `profile_name` char(32) NOT NULL,
  `profile_desc` char(255) NULL DEFAULT NULL,
  PRIMARY KEY (`profile_id`),
  UNIQUE KEY (`profile_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `user_profile`

CREATE TABLE `user_profile` (
  `user_id` int(8) unsigned NOT NULL,
  `profile_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`profile_id`,`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (`profile_id`) REFERENCES `profile` (`profile_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `gp`
-- Entity::Gp class

CREATE TABLE `gp` (
  `gp_id` int(8) unsigned NOT NULL,
  `gp_name` char(32) NOT NULL,
  `gp_type` char(32) NOT NULL,
  `gp_desc` char(255) DEFAULT NULL,
  `gp_system` int(1) unsigned NOT NULL,
  PRIMARY KEY (`gp_id`),
  FOREIGN KEY (`gp_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  UNIQUE KEY (`gp_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `message`
-- Message class

CREATE TABLE `message` (
  `message_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(8) unsigned DEFAULT NULL,
  `message_from` char(32) NOT NULL,
  `message_creationdate` date NOT NULL,
  `message_creationtime` time NOT NULL,
  `message_level` char(32) NOT NULL,
  `message_content` text(512) NOT NULL,
  PRIMARY KEY (`message_id`),
  KEY (`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for `infrastructure`
-- Entity::Infrastructure class

CREATE TABLE `infrastructure` (
  `infrastructure_id` int(8) unsigned NOT NULL,
  `infrastructure_reference` char(64) NOT NULL,
  `infrastructure_min_node` int(2) unsigned NOT NULL,
  `infrastructure_max_node` int(2) unsigned NOT NULL,
  `infrastructure_domainname` char(64) NOT NULL,
  `infrastructure_nameserver` char(15) NOT NULL,
  `infrastructure_name` char(32) NOT NULL,
  `infrastructure_desc` char(255) DEFAULT NULL,
  `infrastructure_version` char(32) NOT NULL,
  `infrastructure_tier_number` int(1),
  `infrastructure_state` char(32) NOT NULL DEFAULT 'down:0',
  `infrastructure_prev_state` char(32),
  `infrastructure_priority` int(1) unsigned NOT NULL,
  PRIMARY KEY (`infrastructure_id`),
  FOREIGN KEY (`infrastructure_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for `tier`
-- Entity::Tier class
-- #TODO Warning Here delete tier when cluster removed by when cluster will be used by tier then they will not be destroyed when cluster are.

CREATE TABLE `tier` (
  `tier_id` int(8) unsigned NOT NULL,
  `infrastructure_id` int(8) unsigned NOT NULL,
  `cluster_id` int(8) unsigned,
  `tier_name` char(32) NOT NULL,
  `tier_rank` int(1) NOT NULL,
  `tier_data_src` char(128) NOT NULL,
  `tier_poststart_script` char(64),
  PRIMARY KEY (`tier_id`),
  FOREIGN KEY (`tier_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`infrastructure_id`),
  FOREIGN KEY (`infrastructure_id`) REFERENCES `infrastructure` (`infrastructure_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`cluster_id`),
  FOREIGN KEY (`cluster_id`) REFERENCES `cluster` (`cluster_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Component management tables
--

--
-- Table structure for table `component_type`
--

CREATE TABLE `component_type` (
  `component_type_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `component_name` char(32) NOT NULL,
  `component_version` char(32) NOT NULL,
  `component_category` char(32) NOT NULL,
  PRIMARY KEY (`component_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `component`
-- Entity::Component class

CREATE TABLE `component` (
  `component_id` int(8) unsigned NOT NULL,
  `service_provider_id` int(8) unsigned,
  `component_type_id` int(8) unsigned NOT NULL,
  `tier_id` int(8) unsigned,
  `component_template_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`component_id`),
  FOREIGN KEY (`component_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`service_provider_id`),
  FOREIGN KEY (`service_provider_id`) REFERENCES `inside` (`inside_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`component_template_id`),
  FOREIGN KEY (`component_template_id`) REFERENCES `component_template` (`component_template_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`component_type_id`),
  FOREIGN KEY (`component_type_id`) REFERENCES `component_type` (`component_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`tier_id`),
  FOREIGN KEY (`tier_id`) REFERENCES `tier` (`tier_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `component_template`
--

CREATE TABLE `component_template` (
  `component_template_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `component_template_name` char(45) NOT NULL,
  `component_template_directory` char(45) NOT NULL,
  `component_type_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`component_template_id`),
  UNIQUE KEY (`component_template_name`),
  KEY (`component_type_id`),
  FOREIGN KEY (`component_type_id`) REFERENCES `component_type` (`component_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `component_template_attr`
--

CREATE TABLE `component_template_attr` (
  `template_component_id` int(8) unsigned NOT NULL,
  `template_component_attr_file` char(45) NOT NULL,
  `component_template_attr_field` char(45) NOT NULL,
  `component_template_attr_type` char(45) NOT NULL,
  PRIMARY KEY (`template_component_id`),
  KEY (`template_component_id`),
  FOREIGN KEY (`template_component_id`) REFERENCES `component_template` (`component_template_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `component_provided`
--

CREATE TABLE `component_provided` (
  `component_type_id` int(8) unsigned NOT NULL,
  `masterimage_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`component_type_id`,`masterimage_id`),
  KEY (`component_type_id`),
  FOREIGN KEY (`component_type_id`) REFERENCES `component_type` (`component_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`masterimage_id`),
  FOREIGN KEY (`masterimage_id`) REFERENCES `masterimage` (`masterimage_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `component_installed`
--

CREATE TABLE `component_installed` (
  `component_type_id` int(8) unsigned NOT NULL,
  `systemimage_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`component_type_id`,`systemimage_id`),
  KEY (`component_type_id`),
  FOREIGN KEY (`component_type_id`) REFERENCES `component_type` (`component_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`systemimage_id`),
  FOREIGN KEY (`systemimage_id`) REFERENCES `systemimage` (`systemimage_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Connector management tables
--

--
-- Table structure for table `connector_type`
--

CREATE TABLE `connector_type` (
  `connector_type_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `connector_name` char(32) NOT NULL,
  `connector_version` char(32) NOT NULL,
  `connector_category` char(32) NOT NULL,
  PRIMARY KEY (`connector_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `connector`
-- Entity::Connector class

CREATE TABLE `connector` (
  `connector_id` int(8) unsigned NOT NULL,
  `service_provider_id` int(8) unsigned,
  `connector_type_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`connector_id`),
  FOREIGN KEY (`connector_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`service_provider_id`),
  FOREIGN KEY (`service_provider_id`) REFERENCES `outside` (`outside_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`connector_type_id`),
  FOREIGN KEY (`connector_type_id`) REFERENCES `connector_type` (`connector_type_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Orchestrator tables
--

--
-- Table structure for orchestrator table `condition`
--

CREATE TABLE `rulecondition` (
  `rulecondition_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `rulecondition_var` char(64) NOT NULL,
  `rulecondition_time_laps` char(32) NOT NULL,
  `rulecondition_consolidation_func` char(32) NOT NULL,
  `rulecondition_transformation_func` char(32) NOT NULL,
  `rulecondition_operator` char(32) NOT NULL,
  `rulecondition_value` int(8) unsigned NOT NULL,
  `rule_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`rulecondition_id`),
  KEY (`rule_id`),
  FOREIGN KEY (`rule_id`) REFERENCES `rule` (`rule_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for orchestrator table `rule`
--

CREATE TABLE `rule` (
  `rule_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `rule_condition` char(128) NOT NULL,
  `cluster_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`rule_id`),
  KEY (`cluster_id`),
  FOREIGN KEY (`cluster_id`) REFERENCES `cluster` (`cluster_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for orchestrator table `workload_characteristic`
--

CREATE TABLE `workload_characteristic` (
  `wc_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `wc_visit_ratio` double NOT NULL,
  `wc_service_time` double NOT NULL,
  `wc_delay` double NOT NULL,
  `wc_think_time` double NOT NULL,
  `cluster_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`wc_id`),
  KEY  (`cluster_id`),
  FOREIGN KEY (`cluster_id`) REFERENCES `cluster` (`cluster_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for orchestrator table `qos_constraint`
--

CREATE TABLE `qos_constraint` (
  `constraint_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `constraint_max_latency` double NOT NULL,
  `constraint_max_abort_rate` double NOT NULL,
  `cluster_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`constraint_id`),
  KEY (`cluster_id`),
  FOREIGN KEY (`cluster_id`) REFERENCES `cluster` (`cluster_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Monitor tables
--

--
-- Table structure for table `indicatorset` (monitor)
--

CREATE TABLE `indicatorset` (
  `indicatorset_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `indicatorset_name` char(16) NOT NULL,
  `indicatorset_provider` char(32) NOT NULL,
  `indicatorset_type` char(32) NOT NULL,
  `indicatorset_component` char(32),
  `indicatorset_max` char(128),
  `indicatorset_tableoid` char(64),
  PRIMARY KEY (`indicatorset_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `indicator` (monitor)
--

CREATE TABLE `indicator` (
  `indicator_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `indicator_name` char(64) NOT NULL,
  `indicator_oid` char(64) NOT NULL,
  `indicator_min` int(8) unsigned,
  `indicator_max` int(8) unsigned,
  `indicator_color` char(8),
  `indicatorset_id` int(8) unsigned DEFAULT NULL,
  `indicator_unit` char(32) DEFAULT NULL,
  PRIMARY KEY (`indicator_id`),
  KEY (`indicatorset_id`),
  FOREIGN KEY (`indicatorset_id`) REFERENCES `indicatorset` (`indicatorset_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `collect` (monitor)
--

CREATE TABLE `collect` (
  `indicatorset_id` int(8) unsigned NOT NULL,
  `cluster_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`indicatorset_id`, `cluster_id`),
  KEY (`indicatorset_id`),
  FOREIGN KEY (`indicatorset_id`) REFERENCES `indicatorset` (`indicatorset_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`cluster_id`),
  FOREIGN KEY (`cluster_id`) REFERENCES `cluster` (`cluster_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `graph` (monitor)
--

CREATE TABLE `graph` (
  `indicatorset_id` int(8) unsigned NOT NULL,
  `cluster_id` int(8) unsigned NOT NULL,
  `graph_type` char(32) NOT NULL,
  `graph_percent` int(1) unsigned,
  `graph_sum` int(1) unsigned,
  `graph_indicators` char(128),
  PRIMARY KEY (`indicatorset_id`, `cluster_id`),
  KEY (`indicatorset_id`),
  FOREIGN KEY (`indicatorset_id`) REFERENCES `indicatorset` (`indicatorset_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`cluster_id`),
  FOREIGN KEY (`cluster_id`) REFERENCES `cluster` (`cluster_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `clustermetric`
--

CREATE TABLE `clustermetric` (
  `clustermetric_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `clustermetric_label` char(255),
  `clustermetric_service_provider_id` int(8) unsigned NOT NULL,
  `clustermetric_indicator_id` int(8) unsigned NOT NULL,
  `clustermetric_statistics_function_name` char(32) NOT NULL,
  `clustermetric_window_time` int(8) unsigned NOT NULL,
  PRIMARY KEY (`clustermetric_id`),
  KEY (`clustermetric_service_provider_id`),
  FOREIGN KEY (`clustermetric_service_provider_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `aggregate_combination`
--

CREATE TABLE `aggregate_combination` (
  `aggregate_combination_id` int(8) unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `aggregate_combination_label` char(255),
  `aggregate_combination_service_provider_id` int(8) unsigned NOT NULL,
  `aggregate_combination_formula` char(32) NOT NULL,
  KEY (`aggregate_combination_service_provider_id`),
  FOREIGN KEY (`aggregate_combination_service_provider_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `aggregate_rule`
--

CREATE TABLE `aggregate_rule` (
  `aggregate_rule_id` int(8) unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `aggregate_rule_label` char(255),
  `aggregate_rule_service_provider_id` int(8) unsigned NOT NULL,
  `aggregate_rule_formula` char(32) NOT NULL ,
  `aggregate_rule_last_eval` int(8) unsigned NULL DEFAULT NULL ,
  `aggregate_rule_timestamp` int(8) unsigned NULL DEFAULT NULL ,
  `aggregate_rule_state` char(32) NOT NULL ,
  `workflow_def_id` int(8) unsigned NULL DEFAULT NULL,
  `aggregate_rule_description` TEXT,
  FOREIGN KEY (`workflow_def_id`) REFERENCES `workflow_def` (`workflow_def_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`aggregate_rule_service_provider_id`),
  FOREIGN KEY (`aggregate_rule_service_provider_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE = InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `aggregate_condition`
--

CREATE TABLE `aggregate_condition` (
  `aggregate_condition_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `aggregate_condition_label` char(255),
  `aggregate_condition_service_provider_id` int(8) unsigned NOT NULL,
  `aggregate_combination_id` int(8) unsigned NOT NULL,
  `comparator` char(32) NOT NULL,
  `threshold` double NOT NULL,
  `state` char(32) NOT NULL,
  `time_limit` char(32),
  `last_eval` BOOLEAN DEFAULT NULL,
  KEY (`aggregate_condition_service_provider_id`),
  FOREIGN KEY (`aggregate_condition_service_provider_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  PRIMARY KEY (`aggregate_condition_id`),
  KEY (`aggregate_combination_id`),
  FOREIGN KEY (`aggregate_combination_id`) REFERENCES `aggregate_combination` (`aggregate_combination_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `nodemetric_combination`
--

CREATE TABLE `nodemetric_combination` (
  `nodemetric_combination_id` int(8) unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `nodemetric_combination_label` char(255),
  `nodemetric_combination_service_provider_id`  int(8) unsigned NOT NULL,
  `nodemetric_combination_formula` char(32) NOT NULL,
  KEY (`nodemetric_combination_service_provider_id`),
  FOREIGN KEY (`nodemetric_combination_service_provider_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE = InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `nodemetric_condition`
--

CREATE TABLE `nodemetric_condition` (
  `nodemetric_condition_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `nodemetric_condition_label` char(255),
  `nodemetric_condition_service_provider_id`  int(8) unsigned NOT NULL,
  `nodemetric_condition_combination_id` int(8) unsigned NOT NULL,
  `nodemetric_condition_comparator` char(32) NOT NULL,
  `nodemetric_condition_threshold` double NOT NULL,
  PRIMARY KEY (`nodemetric_condition_id`),
  KEY (`nodemetric_condition_combination_id`),
  FOREIGN KEY (`nodemetric_condition_combination_id`) REFERENCES `nodemetric_combination` (`nodemetric_combination_id`) ON DELETE CASCADE ON UPDATE NO ACTION,  
  FOREIGN KEY (`nodemetric_condition_service_provider_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `nodemetric_rule`
--

CREATE TABLE `nodemetric_rule` (
  `nodemetric_rule_id` int(8) unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `nodemetric_rule_label` char(255),
  `nodemetric_rule_service_provider_id` int(8) unsigned NOT NULL,
  `nodemetric_rule_formula` char(32) NOT NULL,
  `nodemetric_rule_last_eval` int(8) unsigned NULL DEFAULT NULL,
  `nodemetric_rule_timestamp` int(8) unsigned NULL DEFAULT NULL,
  `nodemetric_rule_state` char(32) NOT NULL,
  `workflow_def_id` int(8) unsigned NULL DEFAULT NULL,
  `nodemetric_rule_description` TEXT,
  FOREIGN KEY (`workflow_def_id`) REFERENCES `workflow_def` (`workflow_def_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`nodemetric_rule_service_provider_id`),
  FOREIGN KEY (`nodemetric_rule_service_provider_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE = InnoDB  DEFAULT CHARSET=utf8;

--
-- Table structure for table `verified_noderule`
--

CREATE TABLE `verified_noderule` (
  `verified_noderule_externalnode_id` int(8) unsigned NOT NULL,
  `verified_noderule_nodemetric_rule_id` int(8) unsigned NOT NULL,
  `verified_noderule_state` char(8) NOT NULL,
  `workflow_def_id` int(8) unsigned default null,
  PRIMARY KEY (`verified_noderule_externalnode_id`,`verified_noderule_nodemetric_rule_id`),
  FOREIGN KEY (`workflow_def_id`) REFERENCES `workflow_def` (`workflow_def_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  KEY (`verified_noderule_nodemetric_rule_id`),
  FOREIGN KEY (`verified_noderule_nodemetric_rule_id`) REFERENCES `nodemetric_rule` (`nodemetric_rule_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY(`verified_noderule_externalnode_id`),
  FOREIGN KEY (`verified_noderule_externalnode_id`) REFERENCES `externalnode` (`externalnode_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE = InnoDB  DEFAULT CHARSET=utf8;


--
-- Table structure for table `ingroups`
--

CREATE TABLE `ingroups` (
  `gp_id` int(8) unsigned NOT NULL,
  `entity_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`gp_id`,`entity_id`),
  KEY (`entity_id`),
  FOREIGN KEY (`entity_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`gp_id`),
  FOREIGN KEY (`gp_id`) REFERENCES `gp` (`gp_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `entityright`
--

CREATE TABLE `entityright` (
  `entityright_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `entityright_consumed_id` int(8) unsigned NOT NULL,
  `entityright_consumer_id` int(8) unsigned NOT NULL,
  `entityright_method` char(64) NOT NULL,
  PRIMARY KEY (`entityright_id`),
  UNIQUE KEY (`entityright_consumed_id`,`entityright_consumer_id`,`entityright_method`),
  KEY (`entityright_consumed_id`),
  FOREIGN KEY (`entityright_consumed_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`entityright_consumer_id`),
  FOREIGN KEY (`entityright_consumer_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `externalcluster`
--

CREATE TABLE `externalcluster` (
  `externalcluster_id` int(8) unsigned NOT NULL,
  `externalcluster_name` char(32) NOT NULL,
  `externalcluster_desc` char(255) DEFAULT NULL,
  `externalcluster_state` char(32) NOT NULL DEFAULT 'down:0',
  `externalcluster_prev_state` char(32),
  PRIMARY KEY (`externalcluster_id`),
  FOREIGN KEY (`externalcluster_id`) REFERENCES `outside` (`outside_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  UNIQUE KEY (`externalcluster_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `externalnode`
--

CREATE TABLE `externalnode` (
  `externalnode_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `externalnode_hostname` char(255) NOT NULL,
  `service_provider_id` int(8) unsigned NOT NULL,
  `externalnode_state` char(32),
  `externalnode_prev_state` char(32),
  PRIMARY KEY (`externalnode_id`),
  UNIQUE KEY (`externalnode_hostname`,`service_provider_id`),
  KEY (`service_provider_id`),
  FOREIGN KEY (`service_provider_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for connector `active_directory`
--

CREATE TABLE `active_directory` (
  `ad_id` int(8) unsigned NOT NULL,
  `ad_host` char(255),
  `ad_user` char(255),
  `ad_pwd` char(32),
  `ad_nodes_base_dn` text(512),
  `ad_usessl` int(1) DEFAULT 1,
  PRIMARY KEY (`ad_id`),
  FOREIGN KEY (`ad_id`) REFERENCES `connector` (`connector_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for connector `scom`
--

CREATE TABLE `scom` (
  `scom_id` int(8) unsigned NOT NULL,
  `scom_ms_name` char(255),
  `scom_usessl` int(1) DEFAULT NULL,
  PRIMARY KEY (`scom_id`),
  FOREIGN KEY (`scom_id`) REFERENCES `connector` (`connector_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for connector `mock_monitor`
--

CREATE TABLE `mock_monitor` (
  `mock_monitor_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`mock_monitor_id`),
  FOREIGN KEY (`mock_monitor_id`) REFERENCES `connector` (`connector_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `masterimage`
-- Entity::Masterimage class

CREATE TABLE `masterimage` (
  `masterimage_id` int(8) unsigned NOT NULL,
  `masterimage_name` char(64) NOT NULL,
  `masterimage_file` char(255) NOT NULL,
  `masterimage_desc` char(255) DEFAULT NULL,
  `masterimage_os` char(64) DEFAULT NULL,
  `masterimage_size` int(8) unsigned NOT NULL,
  PRIMARY KEY (`masterimage_id`),
  FOREIGN KEY (`masterimage_id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `billinglimit`
-- Entity::Billinglimit class
--

CREATE TABLE `billinglimit` (
  `id` int(8) unsigned NOT NULL,
  `start` int(16) NOT NULL,
  `end` int(16) NOT NULL,
  `type` CHAR(32) NOT NULL,
  `soft` BOOLEAN NOT NULL,
  `value` int(8),
  `service_provider_id` int(8) unsigned NOT NULL,
  `repeat` int(16) NOT NULL,
  `repeat_day` int(16) NOT NULL,
  `repeat_start_time` int(16) NOT NULL,
  `repeat_end_time` int(16) NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`id`) REFERENCES `entity` (`entity_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (`service_provider_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `service_template`
--

CREATE TABLE `service_template` (
  `service_template_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `service_name` char(64) NOT NULL,
  `service_desc` char(255) DEFAULT NULL,
  `hosting_policy_id` int(8) unsigned NOT NULL,
  `storage_policy_id` int(8) unsigned DEFAULT NULL,
  `network_policy_id` int(8) unsigned DEFAULT NULL,
  `scalability_policy_id` int(8) unsigned DEFAULT NULL,
  `system_policy_id` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`service_template_id`),
  KEY (`hosting_policy_id`),
  FOREIGN KEY (`hosting_policy_id`) REFERENCES `policy` (`policy_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`storage_policy_id`),
  FOREIGN KEY (`storage_policy_id`) REFERENCES `policy` (`policy_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`network_policy_id`),
  FOREIGN KEY (`network_policy_id`) REFERENCES `policy` (`policy_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`scalability_policy_id`),
  FOREIGN KEY (`scalability_policy_id`) REFERENCES `policy` (`policy_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  KEY (`system_policy_id`),
  FOREIGN KEY (`system_policy_id`) REFERENCES `policy` (`policy_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `policy`
--

CREATE TABLE `policy` (
  `policy_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `param_preset_id` int(8) unsigned NOT NULL,
  `policy_name` char(64) NOT NULL,
  `policy_desc` char(255) DEFAULT NULL,
  `policy_type` char(64) DEFAULT NULL,
  PRIMARY KEY (`policy_id`),
  KEY (`param_preset_id`),
  FOREIGN KEY (`param_preset_id`) REFERENCES `param_preset` (`param_preset_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `param_preset`
--

CREATE TABLE `param_preset` (
  `param_preset_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `name` char(128) DEFAULT NULL,
  `value` char(128) DEFAULT NULL,
  `relation` int(8) unsigned DEFAULT NULL,
  PRIMARY KEY (`param_preset_id`),
  KEY (`relation`),
  FOREIGN KEY (`relation`) REFERENCES `param_preset` (`param_preset_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `scope`
--

CREATE TABLE `scope` (
  `scope_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `scope_name` char(64) NOT NULL,
  PRIMARY KEY (`scope_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `scope_parameter`
--

CREATE TABLE `scope_parameter` (
  `scope_parameter_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `scope_id` int(8) unsigned NOT NULL,
  `scope_parameter_name` char(64) NOT NULL,
  PRIMARY KEY (`scope_parameter_id`),
  UNIQUE KEY (`scope_id`,`scope_parameter_name`),
  FOREIGN KEY (`scope_id`) REFERENCES `scope` (`scope_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `dashboard`
--

CREATE TABLE `dashboard` (
  `dashboard_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `dashboard_config` longtext NOT NULL,
  `dashboard_service_provider_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`dashboard_id`),
  UNIQUE KEY (`dashboard_service_provider_id`),
  FOREIGN KEY (`dashboard_service_provider_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
