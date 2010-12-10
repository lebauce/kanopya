package AdministratorDB::Schema::Dhcpd3Subnet;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("dhcpd3_subnet");
__PACKAGE__->add_columns(
  "dhcpd3_subnet_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "dhcpd3_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "dhcpd3_subnet_net",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 40 },
  "dhcpd3_subnet_mask",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 40 },
);
__PACKAGE__->set_primary_key("dhcpd3_subnet_id");
__PACKAGE__->has_many(
  "dhcpd3_hosts",
  "AdministratorDB::Schema::Dhcpd3Hosts",
  { "foreign.dhcpd3_subnet_id" => "self.dhcpd3_subnet_id" },
);
__PACKAGE__->belongs_to(
  "dhcpd3_id",
  "AdministratorDB::Schema::Dhcpd3",
  { dhcpd3_id => "dhcpd3_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-12-10 10:34:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hVdtfHGeFe22fcspFVhXww


# You can replace this text with custom content, and it will be preserved on regeneration
1;
