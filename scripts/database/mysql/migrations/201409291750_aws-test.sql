CREATE TABLE `aws_account` (
  `aws_account_id` int(8) unsigned NOT NULL,
  `api_access_key` varchar(255) NOT NULL,
  `api_secret_key` varchar(255) NOT NULL,
  `region` varchar(255) NOT NULL,
  PRIMARY KEY (`aws_account_id`),
  FOREIGN KEY (`aws_account_id`) REFERENCES `virtualization` (`virtualization_id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `aws_instance_type` (
  `aws_instance_type_id` int(8) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `ram` int(8) unsigned NOT NULL,
  `cpu` int(4) unsigned NOT NULL,
  `storage` int(8) unsigned NOT NULL,
  PRIMARY KEY (`aws_instance_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO `aws_instance_type` 
  (`aws_instance_type_id`, `name`, `ram`, `cpu`, `storage`) VALUES
  (1, 't2.micro',  1*POW(1024,3), 1, 0),
  (2, 't2.small',  2*POW(1024,3), 1, 0),
  (3, 't2.medium', 4*POW(1024,3), 2, 0)
;

INSERT INTO `class_type` (`class_type`) VALUES 
  ('Entity::Masterimage::AwsMasterimage');

INSERT INTO `component_type` (`component_name`, `component_version`, `deployable`)
  VALUES ('AwsAccount', 6, 1);

INSERT INTO `component_type_category`
  SELECT component_type.component_type_id, component_category.component_category_id
  FROM component_type, component_category 
  WHERE component_type.component_name = 'AwsAccount'
    AND component_category.category_name IN
      ( 'HostManager', 'VirtualMachineManager', 'StorageManager', 'BootManager', 'NetworkManager');
      
  
-- DOWN --

DELETE FROM `component_type_category` WHERE `component_type_id` IN
  (SELECT component_type_id FROM component_type WHERE component_name = 'AwsAccount');
DELETE FROM `component_type` WHERE `component_name` = 'AwsAccount');
DELETE FROM `class_type` WHERE `class_type` = 'Entity::Masterimage::AwsMasterimage');

DROP TABLE IF EXISTS `aws_account`;
DROP TABLE IF EXISTS `aws_instance_type`;