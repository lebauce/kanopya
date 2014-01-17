use utf8;
package Kanopya::Schema::Result::Network;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Network

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

=head1 TABLE: C<network>

=cut

__PACKAGE__->table("network");

=head1 ACCESSORS

=head2 network_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 network_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 network_addr

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 network_netmask

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 network_gateway

  data_type: 'char'
  is_nullable: 0
  size: 15

=cut

__PACKAGE__->add_columns(
  "network_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "network_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "network_addr",
  { data_type => "char", is_nullable => 0, size => 15 },
  "network_netmask",
  { data_type => "char", is_nullable => 0, size => 15 },
  "network_gateway",
  { data_type => "char", is_nullable => 0, size => 15 },
);

=head1 PRIMARY KEY

=over 4

=item * L</network_id>

=back

=cut

__PACKAGE__->set_primary_key("network_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<network_name>

=over 4

=item * L</network_name>

=back

=cut

__PACKAGE__->add_unique_constraint("network_name", ["network_name"]);

=head1 RELATIONS

=head2 clusters

Type: has_many

Related object: L<Kanopya::Schema::Result::Cluster>

=cut

__PACKAGE__->has_many(
  "clusters",
  "Kanopya::Schema::Result::Cluster",
  { "foreign.default_gateway_id" => "self.network_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 dhcpd3_subnets

Type: has_many

Related object: L<Kanopya::Schema::Result::Dhcpd3Subnet>

=cut

__PACKAGE__->has_many(
  "dhcpd3_subnets",
  "Kanopya::Schema::Result::Dhcpd3Subnet",
  { "foreign.network_id" => "self.network_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 network

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "network",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "network_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 poolips

Type: has_many

Related object: L<Kanopya::Schema::Result::Poolip>

=cut

__PACKAGE__->has_many(
  "poolips",
  "Kanopya::Schema::Result::Poolip",
  { "foreign.network_id" => "self.network_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MTqih9+T9jX5xP49VnNkYg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
