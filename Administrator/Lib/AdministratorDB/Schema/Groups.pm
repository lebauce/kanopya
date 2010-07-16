package AdministratorDB::Schema::Groups;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("groups");
__PACKAGE__->add_columns(
  "group_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "group_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "group_desc",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 255 },
  "group_system",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("group_id");
__PACKAGE__->add_unique_constraint("group_name", ["group_name"]);
__PACKAGE__->has_many(
  "entity_groups",
  "AdministratorDB::Schema::EntityGroups",
  { "foreign.group_id" => "self.group_id" },
);
__PACKAGE__->has_many(
  "group_entities",
  "AdministratorDB::Schema::GroupEntity",
  { "foreign.group_id" => "self.group_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-16 15:48:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Jb0kHlscz9/96CtbphO1fA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
