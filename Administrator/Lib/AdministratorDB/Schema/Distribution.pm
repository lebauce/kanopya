package AdministratorDB::Schema::Distribution;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("distribution");
__PACKAGE__->add_columns(
  "distribution_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "distribution_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "distribution_version",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "distribution_desc",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 255 },
  "etc_device_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
  "root_device_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("distribution_id");
__PACKAGE__->has_many(
  "component_provideds",
  "AdministratorDB::Schema::ComponentProvided",
  { "foreign.distribution_id" => "self.distribution_id" },
);
__PACKAGE__->belongs_to(
  "etc_device_id",
  "AdministratorDB::Schema::Lvm2Lv",
  { lvm2_lv_id => "etc_device_id" },
);
__PACKAGE__->belongs_to(
  "root_device_id",
  "AdministratorDB::Schema::Lvm2Lv",
  { lvm2_lv_id => "root_device_id" },
);
__PACKAGE__->has_many(
  "distribution_entities",
  "AdministratorDB::Schema::DistributionEntity",
  { "foreign.distribution_id" => "self.distribution_id" },
);
__PACKAGE__->has_many(
  "systemimages",
  "AdministratorDB::Schema::Systemimage",
  { "foreign.distribution_id" => "self.distribution_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-09-15 21:20:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GGuWswecoIc55FVVGjWqnQ


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::DistributionEntity",
  { "foreign.distribution_id" => "self.distribution_id" },
);

1;
