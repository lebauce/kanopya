package AdministratorDB::Schema::Route;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("route");
__PACKAGE__->add_columns(
  "route_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "publicip_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "ip_destination",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 39 },
  "gateway",
  { data_type => "CHAR", default_value => undef, is_nullable => 1, size => 39 },
);
__PACKAGE__->set_primary_key("route_id");
__PACKAGE__->belongs_to(
  "publicip_id",
  "AdministratorDB::Schema::Publicip",
  { publicip_id => "publicip_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2011-01-07 16:32:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ul8YJN2z9I2Gkt76BWcmFA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
