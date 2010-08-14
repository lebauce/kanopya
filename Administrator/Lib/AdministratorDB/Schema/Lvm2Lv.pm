package AdministratorDB::Schema::Lvm2Lv;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("lvm2_lv");
__PACKAGE__->add_columns(
  "lvm2_vg_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "lvm2_lv_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "lvm2_lv_freespace",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "lvm2_lv_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "lvm2_lv_size",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "lvm2_lv_filesystem",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("lvm2_lv_id");
__PACKAGE__->belongs_to(
  "lvm2_vg_id",
  "AdministratorDB::Schema::Lvm2Vg",
  { lvm2_vg_id => "lvm2_vg_id" },
);
__PACKAGE__->has_many(
  "motherboards",
  "AdministratorDB::Schema::Motherboard",
  { "foreign.etc_device_id" => "self.lvm2_lv_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-14 15:31:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bk/bqb23YRLFfm6O8JQVVA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
