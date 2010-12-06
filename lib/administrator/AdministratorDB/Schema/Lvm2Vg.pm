package AdministratorDB::Schema::Lvm2Vg;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("lvm2_vg");
__PACKAGE__->add_columns(
  "lvm2_vg_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "component_instance_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "lvm2_vg_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "lvm2_vg_freespace",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "lvm2_vg_size",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("lvm2_vg_id");
__PACKAGE__->has_many(
  "lvm2_lvs",
  "AdministratorDB::Schema::Lvm2Lv",
  { "foreign.lvm2_vg_id" => "self.lvm2_vg_id" },
);
__PACKAGE__->has_many(
  "lvm2_pvs",
  "AdministratorDB::Schema::Lvm2Pv",
  { "foreign.lvm2_vg_id" => "self.lvm2_vg_id" },
);
__PACKAGE__->belongs_to(
  "component_instance_id",
  "AdministratorDB::Schema::ComponentInstance",
  { "component_instance_id" => "component_instance_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-12-06 13:00:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gT5YR7hDiHoUHCIqVPE1LA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
