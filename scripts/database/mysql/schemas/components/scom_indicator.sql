
USE `kanopya`;

SET foreign_key_checks=0;

--
-- Table structure for table `scom_indicator`
--

CREATE TABLE `scom_indicator` (
    `indicator_id` int(8) unsigned NOT NULL AUTO_INCREMENT,
    `indicator_name` char(32) NOT NULL,
    `indicator_oid` char(64) NOT NULL,
    `indicator_min` bigint unsigned,
    `indicator_max` bigint unsigned,
    `indicator_unit` char(15),
    `service_provider_id` int(8) unsigned NOT NULL,
    PRIMARY KEY (`indicator_id`),
    CONSTRAINT FOREIGN KEY (`service_provider_id`) REFERENCES `service_provider` (`service_provider_id`) ON DELETE CASCADE ON UPDATE NO ACTION
)   ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET foreign_key_checks=1;
