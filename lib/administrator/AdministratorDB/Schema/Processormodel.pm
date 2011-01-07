package AdministratorDB::Schema::Processormodel;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("processormodel");
__PACKAGE__->add_columns(
  "processormodel_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "processormodel_brand",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "processormodel_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "processormodel_core_num",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "processormodel_clock_speed",
  { data_type => "FLOAT", default_value => undef, is_nullable => 0, size => 32 },
  "processormodel_l2_cache",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "processormodel_max_tdp",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "processormodel_64bits",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("processormodel_id");
__PACKAGE__->add_unique_constraint("processormodel_UNIQUE", ["processormodel_id"]);
__PACKAGE__->has_many(
  "motherboards",
  "AdministratorDB::Schema::Motherboard",
  { "foreign.processormodel_id" => "self.processormodel_id" },
);
__PACKAGE__->has_many(
  "motherboardmodels",
  "AdministratorDB::Schema::Motherboardmodel",
  { "foreign.processormodel_id" => "self.processormodel_id" },
);
__PACKAGE__->has_many(
  "processormodel_entities",
  "AdministratorDB::Schema::ProcessormodelEntity",
  { "foreign.processormodel_id" => "self.processormodel_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-01-07 16:32:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rts+cmoL0t3RUphzJPrYEQ

__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::ProcessormodelEntity",
  { "foreign.processormodel_id" => "self.processormodel_id" },
);
# You can replace this text with custom content, and it will be preserved on regeneration
1;
