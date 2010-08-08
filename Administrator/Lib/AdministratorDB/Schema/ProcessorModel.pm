package AdministratorDB::Schema::ProcessorModel;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("processor_model");
__PACKAGE__->add_columns(
  "processor_model_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "processor_brand",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "processor_model",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "processor_core_num",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "processor_clock_speed",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "processor_fsb",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "processor_l2_cache",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "processor_max_consumption",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "processor_max_tdp",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "processor_64bits",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
  "processor_cpu_flags",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("processor_model_id");
__PACKAGE__->has_many(
  "processor_model_entities",
  "AdministratorDB::Schema::ProcessorModelEntity",
  { "foreign.processor_model_id" => "self.processor_model_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-08 19:33:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:i550gZWY8aFHNgtTCPwf3Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
