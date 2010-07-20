package AdministratorDB::Schema::Motherboardtemplate;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("motherboardtemplate");
__PACKAGE__->add_columns(
  "motherboardtemplate_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "motherboard_brand",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "motherboard_model",
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
  "processortemplate_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("motherboardtemplate_id");
__PACKAGE__->has_many(
  "motherboardtemplate_entities",
  "AdministratorDB::Schema::MotherboardtemplateEntity",
  {
    "foreign.motherboardtemplate_id" => "self.motherboardtemplate_id",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-20 01:31:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7YjWFfNnoPH9HxiJfCDcLQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
