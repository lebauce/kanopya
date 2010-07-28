package AdministratorDB::Schema::Entity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "unused",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("entity_id");
__PACKAGE__->has_many(
  "cluster_entities",
  "AdministratorDB::Schema::ClusterEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_many(
  "component_instance_entities",
  "AdministratorDB::Schema::ComponentInstanceEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_many(
  "distribution_entities",
  "AdministratorDB::Schema::DistributionEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_many(
  "entityright_entityright_consumed_ids",
  "AdministratorDB::Schema::Entityright",
  { "foreign.entityright_consumed_id" => "self.entity_id" },
);
__PACKAGE__->has_many(
  "entityright_entityright_consumer_ids",
  "AdministratorDB::Schema::Entityright",
  { "foreign.entityright_consumer_id" => "self.entity_id" },
);
__PACKAGE__->has_many(
  "groups_entities",
  "AdministratorDB::Schema::GroupsEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_many(
  "ingroups",
  "AdministratorDB::Schema::Ingroups",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_many(
  "kernel_entities",
  "AdministratorDB::Schema::KernelEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_many(
  "motherboard_entities",
  "AdministratorDB::Schema::MotherboardEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_many(
  "motherboard_model_entities",
  "AdministratorDB::Schema::MotherboardModelEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_many(
  "operation_entities",
  "AdministratorDB::Schema::OperationEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_many(
  "operationtype_entities",
  "AdministratorDB::Schema::OperationtypeEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_many(
  "processor_model_entities",
  "AdministratorDB::Schema::ProcessorModelEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_many(
  "systemimage_entities",
  "AdministratorDB::Schema::SystemimageEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_many(
  "user_entities",
  "AdministratorDB::Schema::UserEntity",
  { "foreign.entity_id" => "self.entity_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-27 13:14:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nEiLikg7u7Q+2spaWNB2hw


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->has_one(
  "clusterlink",
  "AdministratorDB::Schema::ClusterEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_one(
  "distributionlink",
  "AdministratorDB::Schema::DistributionEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_one(
  "groupslink",
  "AdministratorDB::Schema::GroupsEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_one(
  "kernellink",
  "AdministratorDB::Schema::KernelEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_one(
  "motherboardlink",
  "AdministratorDB::Schema::MotherboardEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_one(
  "motherboardtemplatelink",
  "AdministratorDB::Schema::MotherboardtemplateEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_one(
  "operationlink",
  "AdministratorDB::Schema::OperationEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_one(
  "operationtypelink",
  "AdministratorDB::Schema::OperationtypeEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_one(
  "processortemplatelink",
  "AdministratorDB::Schema::ProcessortemplateEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_one(
  "systemimagelink",
  "AdministratorDB::Schema::SystemimageEntity",
  { "foreign.entity_id" => "self.entity_id" },
);
__PACKAGE__->has_one(
  "userlink",
  "AdministratorDB::Schema::UserEntity",
  { "foreign.entity_id" => "self.entity_id" },
);

1;
