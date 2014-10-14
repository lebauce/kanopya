CREATE TABLE `aws_account` (
  `aws_account_id` int(8) unsigned NOT NULL,
  `api_access_key` varchar(255) NOT NULL,
  `api_secret_key` varchar(255) NOT NULL,
  `region` varchar(255) NOT NULL,
  PRIMARY KEY (`aws_account_id`),
  FOREIGN KEY (`aws_account_id`) REFERENCES `virtualization` (`virtualization_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `class_type` (`class_type`) VALUES ('Entity::Masterimage::AwsMasterimage');

-- DOWN --

DELETE FROM `class_type` WHERE `class_type` = 'Entity::Masterimage::AwsMasterimage');

DROP TABLE IF EXISTS `aws_account`;