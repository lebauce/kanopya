USE `kanopya`

SET foreign_key_checks=0;

--
-- Table structure for table `glance`
--

CREATE TABLE `glance` (
  `glance_id` int(8) unsigned NOT NULL
  PRIMARY KEY (`glance_id`),
  CONSTRAINT `fk_glance_1` FOREIGN KEY (`glance_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `keystone`
--

CREATE TABLE `keystone` (
  `keystone_id` int(8) unsigned NOT NULL
  PRIMARY KEY (`keystone_id`),
  CONSTRAINT `fk_keystone_1` FOREIGN KEY (`keystone_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `nova_compute`
--

CREATE TABLE `nova_compute` (
  `nova_compute_id` int(8) unsigned NOT NULL
  PRIMARY KEY (`nova_compute_id`),
  CONSTRAINT `fk_nova_compute_1` FOREIGN KEY (`nova_compute_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `nova_controller`
--

CREATE TABLE `nova_controller` (
  `nova_controller_id` int(8) unsigned NOT NULL
  PRIMARY KEY (`nova_controller_id`),
  CONSTRAINT `fk_nova_controller_1` FOREIGN KEY (`nova_controller_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `quantum`
--

CREATE TABLE `quantum` (
  `quantum_id` int(8) unsigned NOT NULL
  PRIMARY KEY (`quantum_id`),
  CONSTRAINT `fk_quantum_1` FOREIGN KEY (`quantum_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
