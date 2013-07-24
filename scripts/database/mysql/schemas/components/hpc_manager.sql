USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `hpc_manager`
--

CREATE TABLE `hpc_manager` (
    `hpc_manager_id` int(8) unsigned NOT NULL,
    `virtualconnect_ip` char(255) NULL DEFAULT NULL,
    `virtualconnect_user` char(255) NULL DEFAULT NULL,
    `bladesystem_ip` char(255) NULL DEFAULT NULL,
    `bladesystem_user` char(255) NULL DEFAULT NULL,
    PRIMARY KEY (`hpc_manager_id`),
    CONSTRAINT `fk_hpc_manager_1` FOREIGN KEY (`hpc_manager_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
