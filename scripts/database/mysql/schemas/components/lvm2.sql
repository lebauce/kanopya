USE `administrator`;

SET foreign_key_checks=0;

--
-- Table structure for table `lvm2`
--

CREATE TABLE `lvm2` (
  `lvm2_id` int(8) unsigned NOT NULL,  
  PRIMARY KEY (`lvm2_id`),
  CONSTRAINT FOREIGN KEY (`lvm2_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `lvm2_vg`
--

CREATE TABLE `lvm2_vg` (
  `lvm2_vg_id` int(8) unsigned NOT NULL AUTO_INCREMENT,  
  `lvm2_id` int(8) unsigned NOT NULL,
  `lvm2_vg_name` char(32) NOT NULL,
  `lvm2_vg_freespace` bigint unsigned NOT NULL,
  `lvm2_vg_size` bigint unsigned NOT NULL,
  PRIMARY KEY (`lvm2_vg_id`),
  KEY `fk_lvm2_vg_1` (`component_instance_id`),
  CONSTRAINT `fk_lvm2_vg_1` FOREIGN KEY (`lvm2_id`) REFERENCES `lvm2` (`lvm2_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `lvm2_pv`
--

CREATE TABLE `lvm2_pv` (
  `lvm2_pv_id` int(8) unsigned NOT NULL AUTO_INCREMENT,  
  `lvm2_vg_id` int(8) unsigned NOT NULL,
  `lvm2_pv_name` char(64) NOT NULL,
  PRIMARY KEY (`lvm2_pv_id`),
  UNIQUE KEY `lvm2_UNIQUE` (`lvm2_pv_name`),
  KEY `fk_lvm2_pv_1` (`lvm2_vg_id`),
  CONSTRAINT `fk_lvm2_pv_1` FOREIGN KEY (`lvm2_vg_id`) REFERENCES `lvm2_vg` (`lvm2_vg_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `lvm2_lv`
--

CREATE TABLE `lvm2_lv` (
  `lvm2_lv_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
  `lvm2_vg_id` int(8) unsigned NOT NULL,
  `lvm2_lv_name` char(32) NOT NULL,
  `lvm2_lv_size` bigint unsigned NOT NULL,
  `lvm2_lv_freespace` bigint unsigned NOT NULL,
  `lvm2_lv_filesystem` char(10) NOT NULL,
  PRIMARY KEY (`lvm2_lv_id`),
  KEY `fk_lvm2_lv_1` (`lvm2_vg_id`),
  CONSTRAINT `fk_lvm2_lv_1` FOREIGN KEY (`lvm2_vg_id`) REFERENCES `lvm2_vg` (`lvm2_vg_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
