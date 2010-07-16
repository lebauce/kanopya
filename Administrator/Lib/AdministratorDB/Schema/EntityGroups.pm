package AdministratorDB::Schema::EntityGroups;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("entity_groups");
__PACKAGE__->add_columns(
  "group_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("group_id", "entity_id");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-14 20:51:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OeqyV6gG6vGysr1mRbP5lA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
