package AdministratorDB::Schema::OperationParameter;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("operation_parameter");
__PACKAGE__->add_columns(
  "operation_param_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "value",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 255 },
  "operation_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("operation_param_id");
__PACKAGE__->belongs_to(
  "operation_id",
  "AdministratorDB::Schema::Operation",
  { operation_id => "operation_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-21 17:39:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4MMIIyDQu9Ck+zQwEw+1SQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
