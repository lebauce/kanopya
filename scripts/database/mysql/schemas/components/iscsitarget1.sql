USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `iscsitarget1`
--

CREATE TABLE `iscsitarget1` (
  `iscsitarget1_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`iscsitarget1_id`),
  CONSTRAINT FOREIGN KEY (`iscsitarget1_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
