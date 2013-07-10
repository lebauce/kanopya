use utf8;
package AdministratorDB::Schema::Result::Dhcpd3Host;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Dhcpd3Host

=cut

use strict;
use warnings;

=head1 BASE CLASS: L<DBIx::Class::IntrospectableM2M>

=cut

use base 'DBIx::Class::IntrospectableM2M';

=head1 LEFT BASE CLASSES

=over 4

=item * L<DBIx::Class::Core>

=back

=cut

use base qw/DBIx::Class::Core/;

=head1 TABLE: C<dhcpd3_hosts>

=cut

__PACKAGE__->table("dhcpd3_hosts");

=head1 ACCESSORS

=head2 dhcpd3_hosts_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 dhcpd3_hosts_pxe

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 dhcpd3_subnet_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 iface_id

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
  "dhcpd3_hosts_pxe",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "dhcpd3_subnet_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "iface_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</dhcpd3_hosts_id>

=back

=cut

__PACKAGE__->set_primary_key("dhcpd3_hosts_id");

=head1 RELATIONS

=head2 dhcpd3_subnet

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Dhcpd3Subnet>

=cut

__PACKAGE__->belongs_to(
  "dhcpd3_subnet",
  "AdministratorDB::Schema::Result::Dhcpd3Subnet",
  { dhcpd3_subnet_id => "dhcpd3_subnet_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 iface

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Iface>

=cut

__PACKAGE__->belongs_to(
  "iface",
  "AdministratorDB::Schema::Result::Iface",
  { iface_id => "iface_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-10 02:56:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wM84SSQvC5dX3Eu2rRQu5w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
