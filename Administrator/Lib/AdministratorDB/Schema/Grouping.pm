package AdministratorDB::Schema::Grouping;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("grouping");
__PACKAGE__->add_columns(
  "groups_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-19 16:58:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oU6iwxKO6bBLIEpFpo1OCw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
