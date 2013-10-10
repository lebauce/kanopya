use utf8;
package AdministratorDB::Schema::Result::Dhcpd3Subnet;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Dhcpd3Subnet

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

=head1 TABLE: C<dhcpd3_subnet>

=cut

__PACKAGE__->table("dhcpd3_subnet");

=head1 ACCESSORS

=head2 dhcpd3_subnet_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 dhcpd3_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 network_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "dhcpd3_subnet_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "dhcpd3_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "network_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</dhcpd3_subnet_id>

=back

=cut

__PACKAGE__->set_primary_key("dhcpd3_subnet_id");

=head1 RELATIONS

=head2 dhcpd3

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Dhcpd3>

=cut

__PACKAGE__->belongs_to(
  "dhcpd3",
  "AdministratorDB::Schema::Result::Dhcpd3",
  { dhcpd3_id => "dhcpd3_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 dhcpd3_hosts

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Dhcpd3Host>

=cut

__PACKAGE__->has_many(
  "dhcpd3_hosts",
  "AdministratorDB::Schema::Result::Dhcpd3Host",
  { "foreign.dhcpd3_subnet_id" => "self.dhcpd3_subnet_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 network

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Network>

=cut

__PACKAGE__->belongs_to(
  "network",
  "AdministratorDB::Schema::Result::Network",
  { network_id => "network_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-09 03:44:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:g9U86OAYYIlkZWNI4JsSoQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
