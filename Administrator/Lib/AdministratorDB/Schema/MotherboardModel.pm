package AdministratorDB::Schema::MotherboardModel;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("motherboard_model");
__PACKAGE__->add_columns(
  "motherboard_model_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "motherboard_brand",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "motherboard_model_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "motherboard_chipset",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "motherboard_processor_num",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
  "motherboard_consumption",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "motherboard_iface_num",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
  "motherboard_ram_slot_num",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
  "motherboard_ram_max",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
  "processor_model_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("motherboard_model_id");
__PACKAGE__->add_unique_constraint("motherboard_model_name_UNIQUE", ["motherboard_model_name"]);
__PACKAGE__->has_many(
  "motherboards",
  "AdministratorDB::Schema::Motherboard",
  { "foreign.motherboard_model_id" => "self.motherboard_model_id" },
);
__PACKAGE__->belongs_to(
  "processor_model_id",
  "AdministratorDB::Schema::ProcessorModel",
  { processor_model_id => "processor_model_id" },
);
__PACKAGE__->has_many(
  "motherboard_model_entities",
  "AdministratorDB::Schema::MotherboardModelEntity",
  { "foreign.motherboard_model_id" => "self.motherboard_model_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-24 00:51:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0tRZTQk+Qpg0Jue6hpntiA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
