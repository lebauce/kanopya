package AdministratorDB::Schema::Result::Dhcpd3Host;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Dhcpd3Host

=cut

__PACKAGE__->table("dhcpd3_hosts");

=head1 ACCESSORS

=head2 dhcpd3_hosts_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 dhcpd3_subnet_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 dhcpd3_hosts_ipaddr

  data_type: 'char'
  is_nullable: 0
  size: 40

=head2 dhcpd3_hosts_mac_address

  data_type: 'char'
  is_nullable: 0
  size: 40

=head2 dhcpd3_hosts_hostname

  data_type: 'char'
  is_nullable: 0
  size: 40

=head2 dhcpd3_hosts_domain_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 dhcpd3_hosts_domain_name_server

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 dhcpd3_hosts_ntp_server

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 kernel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "dhcpd3_hosts_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "dhcpd3_subnet_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "dhcpd3_hosts_ipaddr",
  { data_type => "char", is_nullable => 0, size => 40 },
  "dhcpd3_hosts_mac_address",
  { data_type => "char", is_nullable => 0, size => 40 },
  "dhcpd3_hosts_hostname",
  { data_type => "char", is_nullable => 0, size => 40 },
  "dhcpd3_hosts_domain_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "dhcpd3_hosts_domain_name_server",
  { data_type => "char", is_nullable => 0, size => 15 },
  "dhcpd3_hosts_ntp_server",
  { data_type => "char", is_nullable => 0, size => 15 },
  "kernel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("dhcpd3_hosts_id");
__PACKAGE__->add_unique_constraint("ukey_dhcp3_host_mac", ["dhcpd3_hosts_mac_address"]);
__PACKAGE__->add_unique_constraint("ukey_dhcp3_hostname", ["dhcpd3_hosts_hostname"]);
__PACKAGE__->add_unique_constraint("ukey_dhcp3_host_ipaddr", ["dhcpd3_hosts_ipaddr"]);

=head1 RELATIONS

=head2 dhcpd3_subnet

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Dhcpd3Subnet>

=cut

__PACKAGE__->belongs_to(
  "dhcpd3_subnet",
  "AdministratorDB::Schema::Result::Dhcpd3Subnet",
  { dhcpd3_subnet_id => "dhcpd3_subnet_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 kernel

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Kernel>

=cut

__PACKAGE__->belongs_to(
  "kernel",
  "AdministratorDB::Schema::Result::Kernel",
  { kernel_id => "kernel_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-04-13 10:05:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8k8JM1l4acMdPpZZ36NcMA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
