use utf8;
package Kanopya::Schema::Result::Entity;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Entity

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

=head1 TABLE: C<entity>

=cut

__PACKAGE__->table("entity");

=head1 ACCESSORS

=head2 entity_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 class_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 entity_comment_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 owner_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "entity_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "class_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "entity_comment_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "owner_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</entity_id>

=back

=cut

__PACKAGE__->set_primary_key("entity_id");

=head1 RELATIONS

=head2 aggregate_condition

Type: might_have

Related object: L<Kanopya::Schema::Result::AggregateCondition>

=cut

__PACKAGE__->might_have(
  "aggregate_condition",
  "Kanopya::Schema::Result::AggregateCondition",
  { "foreign.aggregate_condition_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 alert_entities

Type: has_many

Related object: L<Kanopya::Schema::Result::Alert>

=cut

__PACKAGE__->has_many(
  "alert_entities",
  "Kanopya::Schema::Result::Alert",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 alert_trigger_entities

Type: has_many

Related object: L<Kanopya::Schema::Result::Alert>

=cut

__PACKAGE__->has_many(
  "alert_trigger_entities",
  "Kanopya::Schema::Result::Alert",
  { "foreign.trigger_entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 billinglimit

Type: might_have

Related object: L<Kanopya::Schema::Result::Billinglimit>

=cut

__PACKAGE__->might_have(
  "billinglimit",
  "Kanopya::Schema::Result::Billinglimit",
  { "foreign.id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 class_type

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ClassType>

=cut

__PACKAGE__->belongs_to(
  "class_type",
  "Kanopya::Schema::Result::ClassType",
  { class_type_id => "class_type_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 collector_indicator

Type: might_have

Related object: L<Kanopya::Schema::Result::CollectorIndicator>

=cut

__PACKAGE__->might_have(
  "collector_indicator",
  "Kanopya::Schema::Result::CollectorIndicator",
  { "foreign.collector_indicator_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component

Type: might_have

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->might_have(
  "component",
  "Kanopya::Schema::Result::Component",
  { "foreign.component_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 container

Type: might_have

Related object: L<Kanopya::Schema::Result::Container>

=cut

__PACKAGE__->might_have(
  "container",
  "Kanopya::Schema::Result::Container",
  { "foreign.container_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 container_access

Type: might_have

Related object: L<Kanopya::Schema::Result::ContainerAccess>

=cut

__PACKAGE__->might_have(
  "container_access",
  "Kanopya::Schema::Result::ContainerAccess",
  { "foreign.container_access_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entity_comment

Type: belongs_to

Related object: L<Kanopya::Schema::Result::EntityComment>

=cut

__PACKAGE__->belongs_to(
  "entity_comment",
  "Kanopya::Schema::Result::EntityComment",
  { entity_comment_id => "entity_comment_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 entity_lock_consumers

Type: has_many

Related object: L<Kanopya::Schema::Result::EntityLock>

=cut

__PACKAGE__->has_many(
  "entity_lock_consumers",
  "Kanopya::Schema::Result::EntityLock",
  { "foreign.consumer_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entity_lock_entity

Type: might_have

Related object: L<Kanopya::Schema::Result::EntityLock>

=cut

__PACKAGE__->might_have(
  "entity_lock_entity",
  "Kanopya::Schema::Result::EntityLock",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entity_state_consumers

Type: has_many

Related object: L<Kanopya::Schema::Result::EntityState>

=cut

__PACKAGE__->has_many(
  "entity_state_consumers",
  "Kanopya::Schema::Result::EntityState",
  { "foreign.consumer_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entity_state_entities

Type: has_many

Related object: L<Kanopya::Schema::Result::EntityState>

=cut

__PACKAGE__->has_many(
  "entity_state_entities",
  "Kanopya::Schema::Result::EntityState",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entity_tags

Type: has_many

Related object: L<Kanopya::Schema::Result::EntityTag>

=cut

__PACKAGE__->has_many(
  "entity_tags",
  "Kanopya::Schema::Result::EntityTag",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entity_time_periods

Type: has_many

Related object: L<Kanopya::Schema::Result::EntityTimePeriod>

=cut

__PACKAGE__->has_many(
  "entity_time_periods",
  "Kanopya::Schema::Result::EntityTimePeriod",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entityright_entityright_consumers

Type: has_many

Related object: L<Kanopya::Schema::Result::Entityright>

=cut

__PACKAGE__->has_many(
  "entityright_entityright_consumers",
  "Kanopya::Schema::Result::Entityright",
  { "foreign.entityright_consumer_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entityright_entityrights_consumed

Type: has_many

Related object: L<Kanopya::Schema::Result::Entityright>

=cut

__PACKAGE__->has_many(
  "entityright_entityrights_consumed",
  "Kanopya::Schema::Result::Entityright",
  { "foreign.entityright_consumed_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gp

Type: might_have

Related object: L<Kanopya::Schema::Result::Gp>

=cut

__PACKAGE__->might_have(
  "gp",
  "Kanopya::Schema::Result::Gp",
  { "foreign.gp_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 host

Type: might_have

Related object: L<Kanopya::Schema::Result::Host>

=cut

__PACKAGE__->might_have(
  "host",
  "Kanopya::Schema::Result::Host",
  { "foreign.host_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hostmodel

Type: might_have

Related object: L<Kanopya::Schema::Result::Hostmodel>

=cut

__PACKAGE__->might_have(
  "hostmodel",
  "Kanopya::Schema::Result::Hostmodel",
  { "foreign.hostmodel_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 iface

Type: might_have

Related object: L<Kanopya::Schema::Result::Iface>

=cut

__PACKAGE__->might_have(
  "iface",
  "Kanopya::Schema::Result::Iface",
  { "foreign.iface_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator

Type: might_have

Related object: L<Kanopya::Schema::Result::Indicator>

=cut

__PACKAGE__->might_have(
  "indicator",
  "Kanopya::Schema::Result::Indicator",
  { "foreign.indicator_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ingroups

Type: has_many

Related object: L<Kanopya::Schema::Result::Ingroup>

=cut

__PACKAGE__->has_many(
  "ingroups",
  "Kanopya::Schema::Result::Ingroup",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 interface

Type: might_have

Related object: L<Kanopya::Schema::Result::Interface>

=cut

__PACKAGE__->might_have(
  "interface",
  "Kanopya::Schema::Result::Interface",
  { "foreign.interface_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kernel

Type: might_have

Related object: L<Kanopya::Schema::Result::Kernel>

=cut

__PACKAGE__->might_have(
  "kernel",
  "Kanopya::Schema::Result::Kernel",
  { "foreign.kernel_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 masterimage

Type: might_have

Related object: L<Kanopya::Schema::Result::Masterimage>

=cut

__PACKAGE__->might_have(
  "masterimage",
  "Kanopya::Schema::Result::Masterimage",
  { "foreign.masterimage_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 metric

Type: might_have

Related object: L<Kanopya::Schema::Result::Metric>

=cut

__PACKAGE__->might_have(
  "metric",
  "Kanopya::Schema::Result::Metric",
  { "foreign.metric_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netapp_aggregate

Type: might_have

Related object: L<Kanopya::Schema::Result::NetappAggregate>

=cut

__PACKAGE__->might_have(
  "netapp_aggregate",
  "Kanopya::Schema::Result::NetappAggregate",
  { "foreign.aggregate_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netconf

Type: might_have

Related object: L<Kanopya::Schema::Result::Netconf>

=cut

__PACKAGE__->might_have(
  "netconf",
  "Kanopya::Schema::Result::Netconf",
  { "foreign.netconf_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netconf_role

Type: might_have

Related object: L<Kanopya::Schema::Result::NetconfRole>

=cut

__PACKAGE__->might_have(
  "netconf_role",
  "Kanopya::Schema::Result::NetconfRole",
  { "foreign.netconf_role_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 network

Type: might_have

Related object: L<Kanopya::Schema::Result::Network>

=cut

__PACKAGE__->might_have(
  "network",
  "Kanopya::Schema::Result::Network",
  { "foreign.network_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nfs_container_access_client

Type: might_have

Related object: L<Kanopya::Schema::Result::NfsContainerAccessClient>

=cut

__PACKAGE__->might_have(
  "nfs_container_access_client",
  "Kanopya::Schema::Result::NfsContainerAccessClient",
  { "foreign.nfs_container_access_client_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 node

Type: might_have

Related object: L<Kanopya::Schema::Result::Node>

=cut

__PACKAGE__->might_have(
  "node",
  "Kanopya::Schema::Result::Node",
  { "foreign.node_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_condition

Type: might_have

Related object: L<Kanopya::Schema::Result::NodemetricCondition>

=cut

__PACKAGE__->might_have(
  "nodemetric_condition",
  "Kanopya::Schema::Result::NodemetricCondition",
  { "foreign.nodemetric_condition_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 notification_subscription_entities

Type: has_many

Related object: L<Kanopya::Schema::Result::NotificationSubscription>

=cut

__PACKAGE__->has_many(
  "notification_subscription_entities",
  "Kanopya::Schema::Result::NotificationSubscription",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 notification_subscription_subscribers

Type: has_many

Related object: L<Kanopya::Schema::Result::NotificationSubscription>

=cut

__PACKAGE__->has_many(
  "notification_subscription_subscribers",
  "Kanopya::Schema::Result::NotificationSubscription",
  { "foreign.subscriber_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 operation

Type: might_have

Related object: L<Kanopya::Schema::Result::Operation>

=cut

__PACKAGE__->might_have(
  "operation",
  "Kanopya::Schema::Result::Operation",
  { "foreign.operation_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 operationtype

Type: might_have

Related object: L<Kanopya::Schema::Result::Operationtype>

=cut

__PACKAGE__->might_have(
  "operationtype",
  "Kanopya::Schema::Result::Operationtype",
  { "foreign.operationtype_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 owner

Type: belongs_to

Related object: L<Kanopya::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "owner",
  "Kanopya::Schema::Result::User",
  { user_id => "owner_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);

=head2 policy

Type: might_have

Related object: L<Kanopya::Schema::Result::Policy>

=cut

__PACKAGE__->might_have(
  "policy",
  "Kanopya::Schema::Result::Policy",
  { "foreign.policy_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 poolip

Type: might_have

Related object: L<Kanopya::Schema::Result::Poolip>

=cut

__PACKAGE__->might_have(
  "poolip",
  "Kanopya::Schema::Result::Poolip",
  { "foreign.poolip_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 processormodel

Type: might_have

Related object: L<Kanopya::Schema::Result::Processormodel>

=cut

__PACKAGE__->might_have(
  "processormodel",
  "Kanopya::Schema::Result::Processormodel",
  { "foreign.processormodel_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 repository

Type: might_have

Related object: L<Kanopya::Schema::Result::Repository>

=cut

__PACKAGE__->might_have(
  "repository",
  "Kanopya::Schema::Result::Repository",
  { "foreign.repository_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rule

Type: might_have

Related object: L<Kanopya::Schema::Result::Rule>

=cut

__PACKAGE__->might_have(
  "rule",
  "Kanopya::Schema::Result::Rule",
  { "foreign.rule_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider

Type: might_have

Related object: L<Kanopya::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->might_have(
  "service_provider",
  "Kanopya::Schema::Result::ServiceProvider",
  { "foreign.service_provider_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_template

Type: might_have

Related object: L<Kanopya::Schema::Result::ServiceTemplate>

=cut

__PACKAGE__->might_have(
  "service_template",
  "Kanopya::Schema::Result::ServiceTemplate",
  { "foreign.service_template_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 systemimage

Type: might_have

Related object: L<Kanopya::Schema::Result::Systemimage>

=cut

__PACKAGE__->might_have(
  "systemimage",
  "Kanopya::Schema::Result::Systemimage",
  { "foreign.systemimage_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tag

Type: might_have

Related object: L<Kanopya::Schema::Result::Tag>

=cut

__PACKAGE__->might_have(
  "tag",
  "Kanopya::Schema::Result::Tag",
  { "foreign.tag_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 time_period

Type: might_have

Related object: L<Kanopya::Schema::Result::TimePeriod>

=cut

__PACKAGE__->might_have(
  "time_period",
  "Kanopya::Schema::Result::TimePeriod",
  { "foreign.time_period_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user

Type: might_have

Related object: L<Kanopya::Schema::Result::User>

=cut

__PACKAGE__->might_have(
  "user",
  "Kanopya::Schema::Result::User",
  { "foreign.user_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vlan

Type: might_have

Related object: L<Kanopya::Schema::Result::Vlan>

=cut

__PACKAGE__->might_have(
  "vlan",
  "Kanopya::Schema::Result::Vlan",
  { "foreign.vlan_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow

Type: might_have

Related object: L<Kanopya::Schema::Result::Workflow>

=cut

__PACKAGE__->might_have(
  "workflow",
  "Kanopya::Schema::Result::Workflow",
  { "foreign.workflow_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow_def

Type: might_have

Related object: L<Kanopya::Schema::Result::WorkflowDef>

=cut

__PACKAGE__->might_have(
  "workflow_def",
  "Kanopya::Schema::Result::WorkflowDef",
  { "foreign.workflow_def_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gps

Type: many_to_many

Composing rels: L</ingroups> -> gp

=cut

__PACKAGE__->many_to_many("gps", "ingroups", "gp");

=head2 tags

Type: many_to_many

Composing rels: L</entity_tags> -> tag

=cut

__PACKAGE__->many_to_many("tags", "entity_tags", "tag");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-06-27 12:09:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6wuhj5m1pQz7ZgjrdmrYRg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
