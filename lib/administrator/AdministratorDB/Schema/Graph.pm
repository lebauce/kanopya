package AdministratorDB::Schema::Graph;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("graph");
__PACKAGE__->add_columns(
  "indicatorset_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "cluster_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "graph_type",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "graph_percent",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 1 },
  "graph_sum",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 1 },
  "graph_indicators",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 128 },
);
__PACKAGE__->set_primary_key("indicatorset_id", "cluster_id");
__PACKAGE__->belongs_to(
  "indicatorset_id",
  "AdministratorDB::Schema::Indicatorset",
  { indicatorset_id => "indicatorset_id" },
);
__PACKAGE__->belongs_to(
  "cluster_id",
  "AdministratorDB::Schema::Cluster",
  { cluster_id => "cluster_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-01-07 16:32:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:22IS8MUyp0kGWZV1r70NRg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
