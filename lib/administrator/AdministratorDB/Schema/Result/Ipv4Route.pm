package AdministratorDB::Schema::Result::Ipv4Route;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Ipv4Route

=cut

__PACKAGE__->table("ipv4_route");

=head1 ACCESSORS

=head2 ipv4_route_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 ipv4_route_destination

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 ipv4_route_gateway

  data_type: 'char'
  is_nullable: 1
  size: 15

=head2 ipv4_route_context

  data_type: 'char'
  is_nullable: 0
  size: 10

=cut

__PACKAGE__->add_columns(
  "ipv4_route_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "ipv4_route_destination",
  { data_type => "char", is_nullable => 0, size => 15 },
  "ipv4_route_gateway",
  { data_type => "char", is_nullable => 1, size => 15 },
  "ipv4_route_context",
  { data_type => "char", is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("ipv4_route_id");

=head1 RELATIONS

=head2 cluster_ipv4_routes

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ClusterIpv4Route>

=cut

__PACKAGE__->has_many(
  "cluster_ipv4_routes",
  "AdministratorDB::Schema::Result::ClusterIpv4Route",
  { "foreign.ipv4_route_id" => "self.ipv4_route_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-27 08:08:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1Z4EjX6GpM9aIVFKA5gIIg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
