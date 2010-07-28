package AdministratorDB::Schema::Lvm2;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("lvm2");
__PACKAGE__->add_columns(
  "component_instance_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "vgname",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "vgfreespace",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "lvname",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "lvfreespace",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "harddisk_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("component_instance_id");
__PACKAGE__->belongs_to(
  "component_instance_id",
  "AdministratorDB::Schema::ComponentInstance",
  { "component_instance_id" => "component_instance_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-27 13:14:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/6/Lbl6W5aiJ2sI60wUrxw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
