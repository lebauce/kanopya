package AdministratorDB::Schema::Clusterdetails;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("clusterdetails");
__PACKAGE__->add_columns(
  "cluster_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "name",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "value",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("cluster_id", "name");
__PACKAGE__->belongs_to(
  "cluster_id",
  "AdministratorDB::Schema::Cluster",
  { cluster_id => "cluster_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-08-11 14:17:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qYtODTJVTFMX+c0hgLdZcg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
