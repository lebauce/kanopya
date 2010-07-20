package AdministratorDB::Schema::Systemimage;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("systemimage");
__PACKAGE__->add_columns(
  "systemimage_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "systemimage_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "systemimage_desc",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 255 },
  "distribution_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "etc_device_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "root_device_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "systemimage_active",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("systemimage_id");
__PACKAGE__->has_many(
  "systemimage_entities",
  "AdministratorDB::Schema::SystemimageEntity",
  { "foreign.systemimage_id" => "self.systemimage_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-20 01:31:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UMFD1S7mIKfd2sRVxOisfw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
