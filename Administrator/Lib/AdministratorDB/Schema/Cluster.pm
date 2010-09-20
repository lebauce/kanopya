package AdministratorDB::Schema::Cluster;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("cluster");
__PACKAGE__->add_columns(
  "cluster_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "cluster_name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "cluster_desc",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 255 },
  "cluster_type",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 1 },
  "cluster_min_node",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "cluster_max_node",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 2 },
  "cluster_priority",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
  "active",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 1 },
  "systemimage_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
  "kernel_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 8 },
  "cluster_state",
  { data_type => "CHAR", default_value => "down", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("cluster_id");
__PACKAGE__->add_unique_constraint("cluster_name_UNIQUE", ["cluster_name"]);
__PACKAGE__->has_many(
  "cluster_entities",
  "AdministratorDB::Schema::ClusterEntity",
  { "foreign.cluster_id" => "self.cluster_id" },
);
__PACKAGE__->has_many(
  "clusterdetails",
  "AdministratorDB::Schema::Clusterdetails",
  { "foreign.cluster_id" => "self.cluster_id" },
);
__PACKAGE__->has_many(
  "component_instances",
  "AdministratorDB::Schema::ComponentInstance",
  { "foreign.cluster_id" => "self.cluster_id" },
);
__PACKAGE__->has_many(
  "nodes",
  "AdministratorDB::Schema::Node",
  { "foreign.cluster_id" => "self.cluster_id" },
);
__PACKAGE__->has_many(
  "publicips",
  "AdministratorDB::Schema::Publicip",
  { "foreign.cluster_id" => "self.cluster_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-09-20 18:19:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:F2vm88jJIMZaIr93Fk68QA


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::ClusterEntity",
  { "foreign.cluster_id" => "self.cluster_id" },
);

1;
