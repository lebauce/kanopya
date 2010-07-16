package AdministratorDB::Schema::Clusterdetails;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("clusterdetails");
__PACKAGE__->add_columns(
  "cluster_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "key",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 32 },
  "value",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("cluster_id", "key");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-07-14 20:51:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VdG8z/cZDgP85v6qTcFP+A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
