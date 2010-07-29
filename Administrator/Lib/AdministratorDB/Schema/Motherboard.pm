package AdministratorDB::Schema::Motherboard;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("motherboard");
__PACKAGE__->add_columns(
  "motherboard_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "motherboard_model_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "processortemplate_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "kernel_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "motherboard_sn",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "motherboard_slot_position",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
  "motherboard_desc",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 255 },
  "motherboard_active",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
  "motherboard_mac_address",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 18 },
);
__PACKAGE__->set_primary_key("motherboard_id");
__PACKAGE__->has_many(
  "motherboard_entities",
  "AdministratorDB::Schema::MotherboardEntity",
  { "foreign.motherboard_id" => "self.motherboard_id" },
);
__PACKAGE__->has_many(
  "motherboarddetails",
  "AdministratorDB::Schema::Motherboarddetails",
  { "foreign.motherboard_id" => "self.motherboard_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-29 13:51:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VjwAUifTDDf2onzruKXEUg


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::MotherboardEntity",
  { "foreign.motherboard_id" => "self.motherboard_id" },
);

__PACKAGE__->has_many(
  "motherboardext",
  "AdministratorDB::Schema::Motherboarddetails",
  { "foreign.motherboard_id" => "self.motherboard_id" },
);
1;
