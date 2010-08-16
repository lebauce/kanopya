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
);
__PACKAGE__->set_primary_key("openiscsi2_id");
__PACKAGE__->add_unique_constraint("fk_openiscsi2_1", ["component_instance_id"]);
__PACKAGE__->belongs_to(
  "component_instance_id",
  "AdministratorDB::Schema::ComponentInstance",
  { "component_instance_id" => "component_instance_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-16 15:45:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sxlV0z22hv2VvFqLaM4MmA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
