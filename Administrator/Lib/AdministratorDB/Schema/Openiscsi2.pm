package AdministratorDB::Schema::Openiscsi2;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("openiscsi2");
__PACKAGE__->add_columns(
  "openiscsi2_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "component_instance_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "openiscsi2_target",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "openiscsi2_server",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "openiscsi2_port",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 4 },
  "openiscsi2_mount_point",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 64 },
  "openiscsi2_mount_options",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 64 },
  "openiscsi2_filesystem",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 32 },
);
__PACKAGE__->set_primary_key("openiscsi2_id");
__PACKAGE__->belongs_to(
  "component_instance_id",
  "AdministratorDB::Schema::ComponentInstance",
  { "component_instance_id" => "component_instance_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-09-20 18:19:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GxeELvFOYROg18t+9keXCw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
