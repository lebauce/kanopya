package AdministratorDB::Schema::GroupsEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("groups_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "groups_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("entity_id", "groups_id");
__PACKAGE__->add_unique_constraint("fk_groups_entity_2", ["groups_id"]);
__PACKAGE__->add_unique_constraint("fk_groups_entity_1", ["entity_id"]);
__PACKAGE__->belongs_to(
  "entity_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entity_id" },
);
__PACKAGE__->belongs_to(
  "groups_id",
  "AdministratorDB::Schema::Groups",
  { groups_id => "groups_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-11 14:17:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vZX1W7Q4GuvFDWcL4rL74A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
