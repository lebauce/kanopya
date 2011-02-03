package AdministratorDB::Schema::Rulecondition;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("rulecondition");
__PACKAGE__->add_columns(
  "rulecondition_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "rulecondition_var",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "rulecondition_time_laps",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "rulecondition_consolidation_func",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "rulecondition_transformation_func",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "rulecondition_operator",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "rulecondition_value",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "rule_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("rulecondition_id");
__PACKAGE__->belongs_to(
  "rule_id",
  "AdministratorDB::Schema::Rule",
  { rule_id => "rule_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-02-03 09:52:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tZmIphdHylDFC8U5WSIotQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
