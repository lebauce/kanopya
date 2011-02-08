package AdministratorDB::Schema::Indicator;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("indicator");
__PACKAGE__->add_columns(
  "indicator_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "indicator_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "indicator_oid",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 64 },
  "indicator_min",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
  "indicator_max",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
  "indicator_color",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 8 },
  "indicatorset_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("indicator_id");
__PACKAGE__->belongs_to(
  "indicatorset_id",
  "AdministratorDB::Schema::Indicatorset",
  { indicatorset_id => "indicatorset_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-02-03 13:34:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:64wA49q0Ar5hhbmjUcWWsg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
