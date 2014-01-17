use utf8;
package Kanopya::Schema::Result::ServiceProvider;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::ServiceProvider

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

=head1 TABLE: C<service_provider>

=cut

__PACKAGE__->table("service_provider");

=head1 ACCESSORS

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 service_provider_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "service_provider_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</service_provider_id>

=back

=cut

__PACKAGE__->set_primary_key("service_provider_id");

=head1 RELATIONS

=head2 aggregate_conditions

Type: has_many

Related object: L<Kanopya::Schema::Result::AggregateCondition>

=cut

__PACKAGE__->has_many(
  "aggregate_conditions",
  "Kanopya::Schema::Result::AggregateCondition",
  {
    "foreign.aggregate_condition_service_provider_id" => "self.service_provider_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 billinglimits

Type: has_many

Related object: L<Kanopya::Schema::Result::Billinglimit>

=cut

__PACKAGE__->has_many(
  "billinglimits",
  "Kanopya::Schema::Result::Billinglimit",
  { "foreign.service_provider_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cluster

Type: might_have

Related object: L<Kanopya::Schema::Result::Cluster>

=cut

__PACKAGE__->might_have(
  "cluster",
  "Kanopya::Schema::Result::Cluster",
  { "foreign.cluster_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 clustermetrics

Type: has_many

Related object: L<Kanopya::Schema::Result::Clustermetric>

=cut

__PACKAGE__->has_many(
  "clustermetrics",
  "Kanopya::Schema::Result::Clustermetric",
  {
    "foreign.clustermetric_service_provider_id" => "self.service_provider_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 collects

Type: has_many

Related object: L<Kanopya::Schema::Result::Collect>

=cut

__PACKAGE__->has_many(
  "collects",
  "Kanopya::Schema::Result::Collect",
  { "foreign.service_provider_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 combinations

Type: has_many

Related object: L<Kanopya::Schema::Result::Combination>

=cut

__PACKAGE__->has_many(
  "combinations",
  "Kanopya::Schema::Result::Combination",
  { "foreign.service_provider_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 components

Type: has_many

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->has_many(
  "components",
  "Kanopya::Schema::Result::Component",
  { "foreign.service_provider_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 dashboard

Type: might_have

Related object: L<Kanopya::Schema::Result::Dashboard>

=cut

__PACKAGE__->might_have(
  "dashboard",
  "Kanopya::Schema::Result::Dashboard",
  {
    "foreign.dashboard_service_provider_id" => "self.service_provider_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 externalcluster

Type: might_have

Related object: L<Kanopya::Schema::Result::Externalcluster>

=cut

__PACKAGE__->might_have(
  "externalcluster",
  "Kanopya::Schema::Result::Externalcluster",
  { "foreign.externalcluster_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 harddisks

Type: has_many

Related object: L<Kanopya::Schema::Result::Harddisk>

=cut

__PACKAGE__->has_many(
  "harddisks",
  "Kanopya::Schema::Result::Harddisk",
  { "foreign.service_provider_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicators

Type: has_many

Related object: L<Kanopya::Schema::Result::Indicator>

=cut

__PACKAGE__->has_many(
  "indicators",
  "Kanopya::Schema::Result::Indicator",
  { "foreign.service_provider_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 interfaces

Type: has_many

Related object: L<Kanopya::Schema::Result::Interface>

=cut

__PACKAGE__->has_many(
  "interfaces",
  "Kanopya::Schema::Result::Interface",
  { "foreign.service_provider_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netapp

Type: might_have

Related object: L<Kanopya::Schema::Result::Netapp>

=cut

__PACKAGE__->might_have(
  "netapp",
  "Kanopya::Schema::Result::Netapp",
  { "foreign.netapp_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_conditions

Type: has_many

Related object: L<Kanopya::Schema::Result::NodemetricCondition>

=cut

__PACKAGE__->has_many(
  "nodemetric_conditions",
  "Kanopya::Schema::Result::NodemetricCondition",
  {
    "foreign.nodemetric_condition_service_provider_id" => "self.service_provider_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodes

Type: has_many

Related object: L<Kanopya::Schema::Result::Node>

=cut

__PACKAGE__->has_many(
  "nodes",
  "Kanopya::Schema::Result::Node",
  { "foreign.service_provider_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 notification_subscriptions

Type: has_many

Related object: L<Kanopya::Schema::Result::NotificationSubscription>

=cut

__PACKAGE__->has_many(
  "notification_subscriptions",
  "Kanopya::Schema::Result::NotificationSubscription",
  { "foreign.service_provider_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rules

Type: has_many

Related object: L<Kanopya::Schema::Result::Rule>

=cut

__PACKAGE__->has_many(
  "rules",
  "Kanopya::Schema::Result::Rule",
  { "foreign.service_provider_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "service_provider_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 service_provider_managers

Type: has_many

Related object: L<Kanopya::Schema::Result::ServiceProviderManager>

=cut

__PACKAGE__->has_many(
  "service_provider_managers",
  "Kanopya::Schema::Result::ServiceProviderManager",
  { "foreign.service_provider_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider_type

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ServiceProviderType>

=cut

__PACKAGE__->belongs_to(
  "service_provider_type",
  "Kanopya::Schema::Result::ServiceProviderType",
  { service_provider_type_id => "service_provider_type_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 systemimages

Type: has_many

Related object: L<Kanopya::Schema::Result::Systemimage>

=cut

__PACKAGE__->has_many(
  "systemimages",
  "Kanopya::Schema::Result::Systemimage",
  { "foreign.service_provider_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 unified_computing_system

Type: might_have

Related object: L<Kanopya::Schema::Result::UnifiedComputingSystem>

=cut

__PACKAGE__->might_have(
  "unified_computing_system",
  "Kanopya::Schema::Result::UnifiedComputingSystem",
  { "foreign.ucs_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicatorsets

Type: many_to_many

Composing rels: L</collects> -> indicatorset

=cut

__PACKAGE__->many_to_many("indicatorsets", "collects", "indicatorset");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:H5gQ9wwOMpcsL/ElxvpwVA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
