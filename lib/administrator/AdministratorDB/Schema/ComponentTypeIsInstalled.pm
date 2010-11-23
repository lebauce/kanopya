package AdministratorDB::Schema::ComponentTypeIsInstalled;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("component_type_is_installed");
__PACKAGE__->add_columns(
  "system_image_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "component_type_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("system_image_id", "component_type_id");
__PACKAGE__->belongs_to(
  "component_type_id",
  "AdministratorDB::Schema::ComponentType",
  { component_type_id => "component_type_id" },
);
__PACKAGE__->belongs_to(
  "system_image_id",
  "AdministratorDB::Schema::Systemimage",
  { systemimage_id => "system_image_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-26 09:55:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3j2JKPXlw2pFfdsMS1QZug


# You can replace this text with custom content, and it will be preserved on regeneration
1;
