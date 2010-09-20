package AdministratorDB::Schema::Lvm2Pv;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("lvm2_pv");
__PACKAGE__->add_columns(
  "lvm2_pv_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "lvm2_vg_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "lvm2_pv_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
);
__PACKAGE__->set_primary_key("lvm2_pv_id");
__PACKAGE__->add_unique_constraint("lvm2_UNIQUE", ["lvm2_pv_name"]);
__PACKAGE__->belongs_to(
  "lvm2_vg_id",
  "AdministratorDB::Schema::Lvm2Vg",
  { lvm2_vg_id => "lvm2_vg_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-09-20 18:19:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VaK9kHvVkyCr0af4tEpfAg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
