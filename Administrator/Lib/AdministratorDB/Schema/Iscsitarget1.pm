package AdministratorDB::Schema::Iscsitarget1;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("iscsitarget1");
__PACKAGE__->add_columns(
  "component_instance_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "iscsitarget1_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "iscsitarget1_typeio",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 16 },
  "iscsitarget1_targetid",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
  "iscsitarget1_lun",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
  "iscsitarget1_targetname",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 128 },
  "iscsitarget1_iomode",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 10 },
  "iscsitarget1_domain_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
);
__PACKAGE__->set_primary_key("component_instance_id", "iscsitarget1_id");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-08 12:34:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JekWAm1xpEdD7i2UR4dRNg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
