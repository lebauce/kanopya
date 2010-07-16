package AdministratorDB::Schema::Entity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "unused",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("entity_id");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-14 20:51:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IVxJE+Ju4IwJAhqBLtM8lA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
