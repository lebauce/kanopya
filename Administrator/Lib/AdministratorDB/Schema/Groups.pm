package AdministratorDB::Schema::Groups;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("groups");
__PACKAGE__->add_columns(
  "groups_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "groups_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "groups_desc",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 255 },
  "groups_system",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("groups_id");
__PACKAGE__->add_unique_constraint("groups_name", ["groups_name"]);
__PACKAGE__->has_many(
  "groups_entities",
  "AdministratorDB::Schema::GroupsEntity",
  { "foreign.groups_id" => "self.groups_id" },
);
__PACKAGE__->has_many(
  "ingroups",
  "AdministratorDB::Schema::Ingroups",
  { "foreign.groups_id" => "self.groups_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-09-01 00:17:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y0Vb8imvMVnuS0Xy7QXd/Q


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::GroupsEntity",
  { "foreign.groups_id" => "self.groups_id" },
);

1;
