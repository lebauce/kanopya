package AdministratorDB::Schema::Iscsitarget1Target;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("iscsitarget1_target");
__PACKAGE__->add_columns(
  "iscsitarget1_target_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "component_instance_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "iscsitarget1_target_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 128 },
  "mountpoint",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 64 },
  "mount_option",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 32 },
);
__PACKAGE__->set_primary_key("iscsitarget1_target_id");
__PACKAGE__->add_unique_constraint("iscsitarget1_UNIQUE", ["iscsitarget1_target_name"]);
__PACKAGE__->has_many(
  "iscsitarget1_luns",
  "AdministratorDB::Schema::Iscsitarget1Lun",
  {
    "foreign.iscsitarget1_target_id" => "self.iscsitarget1_target_id",
  },
);
__PACKAGE__->belongs_to(
  "component_instance_id",
  "AdministratorDB::Schema::ComponentInstance",
  { "component_instance_id" => "component_instance_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-09-20 18:19:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JvkwYCfABU0d1LGdUlsF+Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
