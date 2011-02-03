package AdministratorDB::Schema::Motherboardmodel;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("motherboardmodel");
__PACKAGE__->add_columns(
  "motherboardmodel_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "motherboardmodel_brand",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "motherboardmodel_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "motherboardmodel_chipset",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "motherboardmodel_processor_num",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
  "motherboardmodel_consumption",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "motherboardmodel_iface_num",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
  "motherboardmodel_ram_slot_num",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
  "motherboardmodel_ram_max",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
  "processormodel_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("motherboardmodel_id");
__PACKAGE__->add_unique_constraint("motherboardmodel_name_UNIQUE", ["motherboardmodel_name"]);
__PACKAGE__->has_many(
  "motherboards",
  "AdministratorDB::Schema::Motherboard",
  { "foreign.motherboardmodel_id" => "self.motherboardmodel_id" },
);
__PACKAGE__->belongs_to(
  "processormodel_id",
  "AdministratorDB::Schema::Processormodel",
  { processormodel_id => "processormodel_id" },
);
__PACKAGE__->has_many(
  "motherboardmodel_entities",
  "AdministratorDB::Schema::MotherboardmodelEntity",
  { "foreign.motherboardmodel_id" => "self.motherboardmodel_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-02-03 13:34:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4KM8Gx/7+fIdhHWU5bc9Ug

__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::MotherboardmodelEntity",
  { "foreign.motherboardmodel_id" => "self.motherboardmodel_id" },
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
