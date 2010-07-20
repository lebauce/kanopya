package AdministratorDB::Schema::Grouping;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("grouping");
__PACKAGE__->add_columns(
  "groups_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("groups_id", "entity_id");
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


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-20 01:31:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nlFj0+mVgIpmvjIfZTiBlA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
