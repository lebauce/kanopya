package AdministratorDB::Schema::Result::Cluster;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Cluster

=cut

__PACKAGE__->table("cluster");

=head1 ACCESSORS

=head2 cluster_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 cluster_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 cluster_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 cluster_type

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 cluster_min_node

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 cluster_max_node

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 cluster_priority

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 cluster_si_location

  data_type: 'enum'
  extra: {list => ["local","diskless"]}
  is_nullable: 0

=head2 cluster_si_access_mode

  data_type: 'enum'
  extra: {list => ["ro","rw"]}
  is_nullable: 0

=head2 cluster_si_shared

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 cluster_domainname

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 cluster_nameserver

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 active

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 systemimage_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 kernel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 cluster_state

  data_type: 'char'
  default_value: 'down'
  is_nullable: 0
  size: 32

=head2 cluster_prev_state

  data_type: 'char'
  is_nullable: 1
  size: 32
  
=head2 cluster_basehostname

  data_type: 'char'
  is_nullable: 0
  size: 64


=cut

__PACKAGE__->add_columns(
  "cluster_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "cluster_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "cluster_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "cluster_type",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "cluster_min_node",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "cluster_max_node",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "cluster_priority",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "cluster_si_location",
  {
    data_type => "enum",
    extra => { list => ["local", "diskless"] },
    is_nullable => 0,
  },
  "cluster_si_access_mode",
  {
    data_type => "enum",
    extra => { list => ["ro", "rw"] },
    is_nullable => 0,
  },
  "cluster_si_shared",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "cluster_domainname",
  { data_type => "char", is_nullable => 0, size => 64 },
  "cluster_nameserver",
  { data_type => "char", is_nullable => 0, size => 15 },
  "active",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "systemimage_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "kernel_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "cluster_state",
  { data_type => "char", default_value => "down", is_nullable => 0, size => 32 },
  "cluster_prev_state",
  { data_type => "char", is_nullable => 1, size => 32 },
   "cluster_basehostname",
  { data_type => "char", is_nullable => 0, size => 64 },
);
__PACKAGE__->set_primary_key("cluster_id");
__PACKAGE__->add_unique_constraint("cluster_name_UNIQUE", ["cluster_name"]);

=head1 RELATIONS

=head2 cluster_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::ClusterEntity>

=cut

__PACKAGE__->might_have(
  "cluster_entity",
  "AdministratorDB::Schema::Result::ClusterEntity",
  { "foreign.cluster_id" => "self.cluster_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cluster_ipv4_routes

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ClusterIpv4Route>

=cut

__PACKAGE__->has_many(
  "cluster_ipv4_routes",
  "AdministratorDB::Schema::Result::ClusterIpv4Route",
  { "foreign.cluster_id" => "self.cluster_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 clusterdetails

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Clusterdetail>

=cut

__PACKAGE__->has_many(
  "clusterdetails",
  "AdministratorDB::Schema::Result::Clusterdetail",
  { "foreign.cluster_id" => "self.cluster_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 collects

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Collect>

=cut

__PACKAGE__->has_many(
  "collects",
  "AdministratorDB::Schema::Result::Collect",
  { "foreign.cluster_id" => "self.cluster_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component_instances

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ComponentInstance>

=cut

__PACKAGE__->has_many(
  "component_instances",
  "AdministratorDB::Schema::Result::ComponentInstance",
  { "foreign.cluster_id" => "self.cluster_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 graphs

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Graph>

=cut

__PACKAGE__->has_many(
  "graphs",
  "AdministratorDB::Schema::Result::Graph",
  { "foreign.cluster_id" => "self.cluster_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ipv4_publics

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Ipv4Public>

=cut

__PACKAGE__->has_many(
  "ipv4_publics",
  "AdministratorDB::Schema::Result::Ipv4Public",
  { "foreign.cluster_id" => "self.cluster_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodes

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Node>

=cut

__PACKAGE__->has_many(
  "nodes",
  "AdministratorDB::Schema::Result::Node",
  { "foreign.cluster_id" => "self.cluster_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qos_constraints

Type: has_many

Related object: L<AdministratorDB::Schema::Result::QosConstraint>

=cut

__PACKAGE__->has_many(
  "qos_constraints",
  "AdministratorDB::Schema::Result::QosConstraint",
  { "foreign.cluster_id" => "self.cluster_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rules

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Rule>

=cut

__PACKAGE__->has_many(
  "rules",
  "AdministratorDB::Schema::Result::Rule",
  { "foreign.cluster_id" => "self.cluster_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tiers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Tier>

=cut

__PACKAGE__->has_many(
  "tiers",
  "AdministratorDB::Schema::Result::Tier",
  { "foreign.cluster_id" => "self.cluster_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workload_characteristics

Type: has_many

Related object: L<AdministratorDB::Schema::Result::WorkloadCharacteristic>

=cut

__PACKAGE__->has_many(
  "workload_characteristics",
  "AdministratorDB::Schema::Result::WorkloadCharacteristic",
  { "foreign.cluster_id" => "self.cluster_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-10-01 12:16:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YQHjwHosYkYAKMqNmT4uaQ


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::ClusterEntity",
    { "foreign.cluster_id" => "self.cluster_id" },
    { cascade_copy => 0, cascade_delete => 0 });
1;
