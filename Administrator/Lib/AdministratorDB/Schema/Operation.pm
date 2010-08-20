package AdministratorDB::Schema::Operation;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("operation");
__PACKAGE__->add_columns(
  "operation_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "type",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "priority",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "creation_date",
  { data_type => "DATE", default_value => undef, is_nullable => 0, size => 10 },
  "creation_time",
  { data_type => "TIME", default_value => undef, is_nullable => 0, size => 8 },
  "execution_rank",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("operation_id");
__PACKAGE__->add_unique_constraint("execution_rank_UNIQUE", ["execution_rank"]);
__PACKAGE__->belongs_to(
  "user_id",
  "AdministratorDB::Schema::User",
  { user_id => "user_id" },
);
__PACKAGE__->belongs_to(
  "type",
  "AdministratorDB::Schema::Operationtype",
  { operationtype_name => "type" },
);
__PACKAGE__->has_many(
  "operation_entities",
  "AdministratorDB::Schema::OperationEntity",
  { "foreign.operation_id" => "self.operation_id" },
);
__PACKAGE__->has_many(
  "operation_parameters",
  "AdministratorDB::Schema::OperationParameter",
  { "foreign.operation_id" => "self.operation_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-20 14:40:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zcvrJNxCgTlvQPsjlRP0dg


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::OperationEntity",
  { "foreign.operation_id" => "self.operation_id" },
);

1;
