package AdministratorDB::Schema::Indicatorset;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("indicatorset");
__PACKAGE__->add_columns(
  "indicatorset_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "indicatorset_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 16 },
  "indicatorset_provider",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "indicatorset_type",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "indicatorset_component",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 32 },
  "indicatorset_max",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 128 },
);
__PACKAGE__->set_primary_key("indicatorset_id");
__PACKAGE__->has_many(
  "collects",
  "AdministratorDB::Schema::Collect",
  { "foreign.indicatorset_id" => "self.indicatorset_id" },
);
__PACKAGE__->has_many(
  "graphs",
  "AdministratorDB::Schema::Graph",
  { "foreign.indicatorset_id" => "self.indicatorset_id" },
);
__PACKAGE__->has_many(
  "indicators",
  "AdministratorDB::Schema::Indicator",
  { "foreign.indicatorset_id" => "self.indicatorset_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-01-07 16:32:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KWK0vGYs8RhUXu9PVgkqbw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
