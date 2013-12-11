use utf8;
package Kanopya::Schema::Result::Cluster;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Cluster

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

=head1 TABLE: C<cluster>

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
  is_nullable: 1
  size: 64

=head2 default_gateway_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

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

=head2 service_template_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
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
  { data_type => "char", is_nullable => 1, size => 64 },
  "default_gateway_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
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
  "service_template_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</cluster_id>

=back

=cut

__PACKAGE__->set_primary_key("cluster_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<cluster_basehostname>

=over 4

=item * L</cluster_basehostname>

=back

=cut

__PACKAGE__->add_unique_constraint("cluster_basehostname", ["cluster_basehostname"]);

=head2 C<cluster_name>

=over 4

=item * L</cluster_name>

=back

=cut

__PACKAGE__->add_unique_constraint("cluster_name", ["cluster_name"]);

=head1 RELATIONS

=head2 cluster

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "cluster",
  "Kanopya::Schema::Result::ServiceProvider",
  { service_provider_id => "cluster_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 default_gateway

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Network>

=cut

__PACKAGE__->belongs_to(
  "default_gateway",
  "Kanopya::Schema::Result::Network",
  { network_id => "default_gateway_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 kernel

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Kernel>

=cut

__PACKAGE__->belongs_to(
  "kernel",
  "Kanopya::Schema::Result::Kernel",
  { kernel_id => "kernel_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 masterimage

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Masterimage>

=cut

__PACKAGE__->belongs_to(
  "masterimage",
  "Kanopya::Schema::Result::Masterimage",
  { masterimage_id => "masterimage_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 qos_constraints

Type: has_many

Related object: L<Kanopya::Schema::Result::QosConstraint>

=cut

__PACKAGE__->has_many(
  "qos_constraints",
  "Kanopya::Schema::Result::QosConstraint",
  { "foreign.cluster_id" => "self.cluster_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_template

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ServiceTemplate>

=cut

__PACKAGE__->belongs_to(
  "service_template",
  "Kanopya::Schema::Result::ServiceTemplate",
  { service_template_id => "service_template_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 user

Type: belongs_to

Related object: L<Kanopya::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Kanopya::Schema::Result::User",
  { user_id => "user_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 workload_characteristics

Type: has_many

Related object: L<Kanopya::Schema::Result::WorkloadCharacteristic>

=cut

__PACKAGE__->has_many(
  "workload_characteristics",
  "Kanopya::Schema::Result::WorkloadCharacteristic",
  { "foreign.cluster_id" => "self.cluster_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-12-05 15:56:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+PH1yTPWIEemD3L125XAcA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
