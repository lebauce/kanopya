USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `kanopya_stack_builder`
--

CREATE TABLE `kanopya_stack_builder` (
    `kanopya_stack_builder_id` int(8) unsigned NOT NULL,
    `support_user_id` int(8) unsigned DEFAULT NULL,
    PRIMARY KEY (`kanopya_stack_builder_id`),
    FOREIGN KEY (`kanopya_stack_builder_id`) REFERENCES `component` (`component_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
    FOREIGN KEY (`support_user_id`) REFERENCES `user` (`user_id`) ON DELETE SET NULL ON UPDATE NO ACTION
)   ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `customer`
-- Entity::User::Customer class

CREATE TABLE `stack_builder_customer` (
  `stack_builder_customer_id` int(8) unsigned NOT NULL,
  PRIMARY KEY (`stack_builder_customer_id`),
  FOREIGN KEY (`stack_builder_customer_id`) REFERENCES `customer` (`customer_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
