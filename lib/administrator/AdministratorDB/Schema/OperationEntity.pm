package AdministratorDB::Schema::OperationEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("operation_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "operation_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("entity_id", "operation_id");
__PACKAGE__->add_unique_constraint("fk_operation_entity_1", ["entity_id"]);
__PACKAGE__->add_unique_constraint("fk_operation_entity_2", ["operation_id"]);
__PACKAGE__->belongs_to(
  "entity_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entity_id" },
);
__PACKAGE__->belongs_to(
  "operation_id",
  "AdministratorDB::Schema::Operation",
  { operation_id => "operation_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-02-03 09:52:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6Yftqtmy0Kq5F9lG039ZHg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
