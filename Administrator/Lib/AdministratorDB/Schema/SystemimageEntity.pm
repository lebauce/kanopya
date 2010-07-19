package AdministratorDB::Schema::SystemimageEntity;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("systemimage_entity");
__PACKAGE__->add_columns(
  "entity_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "systemimage_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("entity_id", "systemimage_id");
__PACKAGE__->belongs_to(
  "entity_id",
  "AdministratorDB::Schema::Entity",
  { entity_id => "entity_id" },
);
__PACKAGE__->belongs_to(
  "systemimage_id",
  "AdministratorDB::Schema::Systemimage",
  { systemimage_id => "systemimage_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-19 16:58:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Q34bCl9IeW54muQdt/f/+g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
