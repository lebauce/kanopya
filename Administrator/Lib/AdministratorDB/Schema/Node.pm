package AdministratorDB::Schema::Node;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("node");
__PACKAGE__->add_columns(
  "node_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "cluster_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "motherboard_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "master_node",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("node_id");
__PACKAGE__->belongs_to(
  "cluster_id",
  "AdministratorDB::Schema::Cluster",
  { cluster_id => "cluster_id" },
);
__PACKAGE__->belongs_to(
  "motherboard_id",
  "AdministratorDB::Schema::Motherboard",
  { motherboard_id => "motherboard_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-09-17 14:10:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1XM+ibPJ/sanBjczMKEDlA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
