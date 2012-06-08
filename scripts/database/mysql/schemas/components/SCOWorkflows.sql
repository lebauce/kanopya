USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `sco_workflows`
--

CREATE TABLE `sco_workflows` (
    `sco_workflow_manager_id` int(8) unsigned,
    `workflow_def_id` int (8) unsigned,
    UNIQUE KEY (`sco_workflow_manager_id`, `workflow_def_id`),
    CONSTRAINT FOREIGN KEY (`sco_workflow_manager_id`) REFERENCES `connector` (`connector_id`) ON DELETE CASCADE ON UPDATE NO ACTION
)   ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
