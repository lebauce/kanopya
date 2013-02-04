USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `amqp`
--

CREATE TABLE `amqp` (
  `amqp_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`amqp_id`),
  CONSTRAINT `fk_amqp_1` FOREIGN KEY (`amqp_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
