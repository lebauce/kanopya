USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `kanopya_deployment_manager`
--

CREATE TABLE `kanopya_deployment_manager` (
    `kanopya_deployment_manager_id` int(8) unsigned NOT NULL,
    `dhcp_component_id` int(8) unsigned NOT NULL,
    `tftp_component_id` int(8) unsigned NOT NULL,
    `system_component_id` int(8) unsigned NOT NULL,
    PRIMARY KEY (`kanopya_deployment_manager_id`),
    FOREIGN KEY (`kanopya_deployment_manager_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
    FOREIGN KEY (`dhcp_component_id`) REFERENCES `component` (`component_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (`tftp_component_id`) REFERENCES `component` (`component_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (`system_component_id`) REFERENCES `component` (`component_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
)   ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `systemimage_container_access`
-- Entity::SystemimageContainerAccess link class

CREATE TABLE `systemimage_container_access` (
  `systemimage_id` int(8) unsigned NOT NULL,
  `container_access_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`systemimage_id`, `container_access_id`),
  FOREIGN KEY (`systemimage_id`) REFERENCES `systemimage` (`systemimage_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  FOREIGN KEY (`container_access_id`) REFERENCES `container_access` (`container_access_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
