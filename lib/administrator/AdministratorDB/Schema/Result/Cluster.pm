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
  is_foreign_key: 1
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

=head2 cluster_boot_policy

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 cluster_si_shared

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 cluster_si_persistent

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 cluster_domainname

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 cluster_nameserver1

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 cluster_nameserver2

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 cluster_state

  data_type: 'char'
  default_value: 'down:0'
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

=head2 active

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 kernel_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 masterimage_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 host_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 disk_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 export_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 collector_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cluster_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
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
  "cluster_boot_policy",
  { data_type => "char", is_nullable => 0, size => 32 },
  "cluster_si_shared",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "cluster_si_persistent",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "cluster_domainname",
  { data_type => "char", is_nullable => 0, size => 64 },
  "cluster_nameserver1",
  { data_type => "char", is_nullable => 0, size => 15 },
  "cluster_nameserver2",
  { data_type => "char", is_nullable => 0, size => 15 },
  "cluster_state",
  {
    data_type => "char",
    default_value => "down:0",
    is_nullable => 0,
    size => 32,
  },
  "cluster_prev_state",
  { data_type => "char", is_nullable => 1, size => 32 },
  "cluster_basehostname",
  { data_type => "char", is_nullable => 0, size => 64 },
  "active",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "user_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "kernel_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "masterimage_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "host_manager_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "disk_manager_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "export_manager_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "collector_manager_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("cluster_id");
__PACKAGE__->add_unique_constraint("cluster_name", ["cluster_name"]);

=head1 RELATIONS

=head2 cluster

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Inside>

=cut

__PACKAGE__->belongs_to(
  "cluster",
  "AdministratorDB::Schema::Result::Inside",
  { inside_id => "cluster_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 user

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "AdministratorDB::Schema::Result::User",
  { user_id => "user_id" },
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
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 masterimage

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Masterimage>

=cut

__PACKAGE__->belongs_to(
  "masterimage",
  "AdministratorDB::Schema::Result::Masterimage",
  { masterimage_id => "masterimage_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
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

=head2 manager_parameters

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ManagerParameter>

=cut

__PACKAGE__->has_many(
  "manager_parameters",
  "AdministratorDB::Schema::Result::ManagerParameter",
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


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-04-30 17:35:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3PTgsMlU016jrqt43zymHQ

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Inside",
         { "foreign.inside_id" => "self.cluster_id" },
         { cascade_copy => 0, cascade_delete => 1 }
);

1;
