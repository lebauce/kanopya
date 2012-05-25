USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `scom_indicator`
--

CREATE TABLE `scom_indicator` (
    `scom_indicator_id` int(8) unsigned NOT NULL,
    `scom_indicator_name` char(32) NOT NULL,
    `scom_indicator_oid` char(64) NOT NULL,
	`scom_indicator_min` bigint unsigned,
	`scom_indicator_max` bigint unsigned,
	`scom_indicator_unit` char(15),
	`class_type_id` int(8) unsigned NOT NULL,
	`service_provider_id` int(8) unsigned NOT NULL,
    PRIMARY KEY (`scom_indicator_id`),
    CONSTRAINT FOREIGN KEY (`class_type_id`) REFERENCES `class_type` (`class_type_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
	CONSTRAINT FOREIGN KEY (`service_provider_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE CASCADE ON UPDATE NO ACTION
)   ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
