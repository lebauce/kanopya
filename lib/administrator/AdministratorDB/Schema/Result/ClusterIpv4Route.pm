package AdministratorDB::Schema::Result::ClusterIpv4Route;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ClusterIpv4Route

=cut

__PACKAGE__->table("cluster_ipv4_route");

=head1 ACCESSORS

=head2 cluster_ipv4_route_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 cluster_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 ipv4_route_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cluster_ipv4_route_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "cluster_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "ipv4_route_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("cluster_ipv4_route_id");
__PACKAGE__->add_unique_constraint("index4", ["cluster_id", "ipv4_route_id"]);

=head1 RELATIONS

=head2 cluster

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Cluster>

=cut

__PACKAGE__->belongs_to(
  "cluster",
  "AdministratorDB::Schema::Result::Cluster",
  { cluster_id => "cluster_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 ipv4_route

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Ipv4Route>

=cut

__PACKAGE__->belongs_to(
  "ipv4_route",
  "AdministratorDB::Schema::Result::Ipv4Route",
  { ipv4_route_id => "ipv4_route_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-03-07 00:25:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6sSmA850uYYfzHXkBp5p1A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
