package AdministratorDB::Schema::Iscsitarget1Lun;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("iscsitarget1_lun");
__PACKAGE__->add_columns(
  "iscsitarget1_lun_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "iscsitarget1_target_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "iscsitarget1_lun_number",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "iscsitarget1_lun_device",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "iscsitarget1_lun_typeio",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "iscsitarget1_lun_iomode",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 16 },
);
__PACKAGE__->set_primary_key("iscsitarget1_lun_id");
__PACKAGE__->belongs_to(
  "iscsitarget1_target_id",
  "AdministratorDB::Schema::Iscsitarget1Target",
  { "iscsitarget1_target_id" => "iscsitarget1_target_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-26 17:52:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UT0S7bVhrk7aPnGb0+pBOQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
