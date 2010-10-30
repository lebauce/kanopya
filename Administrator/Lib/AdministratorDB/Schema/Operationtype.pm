package AdministratorDB::Schema::Operationtype;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("operationtype");
__PACKAGE__->add_columns(
  "operationtype_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "operationtype_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("operationtype_id");
__PACKAGE__->add_unique_constraint("operationtype_name_UNIQUE", ["operationtype_name"]);
__PACKAGE__->has_many(
  "operations",
  "AdministratorDB::Schema::Operation",
  { "foreign.type" => "self.operationtype_name" },
);
__PACKAGE__->has_many(
  "operationtype_entities",
  "AdministratorDB::Schema::OperationtypeEntity",
  { "foreign.operationtype_id" => "self.operationtype_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-10-30 04:18:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DZN/8tIXH1uybmF3F5PHJA


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::OperationtypeEntity",
  { "foreign.operationtype_id" => "self.operationtype_id" },
);

1;
