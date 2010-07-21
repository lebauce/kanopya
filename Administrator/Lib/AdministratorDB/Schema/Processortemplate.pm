package AdministratorDB::Schema::Processortemplate;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("processortemplate");
__PACKAGE__->add_columns(
  "processortemplate_id",
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
__PACKAGE__->set_primary_key("processortemplate_id");
__PACKAGE__->has_many(
  "processortemplate_entities",
  "AdministratorDB::Schema::ProcessortemplateEntity",
  { "foreign.processortemplate_id" => "self.processortemplate_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-21 19:05:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Oj9REVLz+0bdjmaHlCY8XA


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::ProcessortemplateEntity",
  { "foreign.processortemplate_id" => "self.processortemplate_id" },
);


1;
