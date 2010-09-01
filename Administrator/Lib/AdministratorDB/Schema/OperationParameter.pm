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


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-09-01 00:17:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SCDqWdtZ1ieadUdKwylf4w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
