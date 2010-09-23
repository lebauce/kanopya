package AdministratorDB::Schema::Dhcpd3Hosts;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("+AdministratorDB::EntityBase", "Core");
__PACKAGE__->table("dhcpd3_hosts");
__PACKAGE__->add_columns(
  "dhcpd3_hosts_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "dhcpd3_subnet_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
  "dhcpd3_hosts_ipaddr",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 40 },
  "dhcpd3_hosts_mac_address",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 40 },
  "dhcpd3_hosts_hostname",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 40 },
  "kernel_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("dhcpd3_hosts_id");
__PACKAGE__->belongs_to(
  "dhcpd3_subnet_id",
  "AdministratorDB::Schema::Dhcpd3Subnet",
  { dhcpd3_subnet_id => "dhcpd3_subnet_id" },
);
__PACKAGE__->belongs_to(
  "kernel_id",
  "AdministratorDB::Schema::Kernel",
  { kernel_id => "kernel_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-09-23 17:23:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:imLB30n3v8k6PVp3nGVv1g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
