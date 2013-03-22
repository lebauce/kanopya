use utf8;
package AdministratorDB::Schema::Result::Entity;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Entity

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

Related object: L<AdministratorDB::Schema::Result::AggregateCondition>

=cut

__PACKAGE__->might_have(
  "aggregate_condition",
  "AdministratorDB::Schema::Result::AggregateCondition",
  { "foreign.aggregate_condition_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 alert_entities

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Alert>

=cut

__PACKAGE__->has_many(
  "alert_entities",
  "AdministratorDB::Schema::Result::Alert",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 alert_trigger_entities

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Alert>

=cut

__PACKAGE__->has_many(
  "alert_trigger_entities",
  "AdministratorDB::Schema::Result::Alert",
  { "foreign.trigger_entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 billinglimit

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Billinglimit>

=cut

__PACKAGE__->might_have(
  "billinglimit",
  "AdministratorDB::Schema::Result::Billinglimit",
  { "foreign.id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 class_type

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ClassType>

=cut

__PACKAGE__->belongs_to(
  "class_type",
  "AdministratorDB::Schema::Result::ClassType",
  { class_type_id => "class_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 clustermetric

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Clustermetric>

=cut

__PACKAGE__->might_have(
  "clustermetric",
  "AdministratorDB::Schema::Result::Clustermetric",
  { "foreign.clustermetric_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 collector_indicator

Type: might_have

Related object: L<AdministratorDB::Schema::Result::CollectorIndicator>

=cut

__PACKAGE__->might_have(
  "collector_indicator",
  "AdministratorDB::Schema::Result::CollectorIndicator",
  { "foreign.collector_indicator_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 combination

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Combination>

=cut

__PACKAGE__->might_have(
  "combination",
  "AdministratorDB::Schema::Result::Combination",
  { "foreign.combination_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->might_have(
  "component",
  "AdministratorDB::Schema::Result::Component",
  { "foreign.component_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 container

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Container>

=cut

__PACKAGE__->might_have(
  "container",
  "AdministratorDB::Schema::Result::Container",
  { "foreign.container_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 container_access

Type: might_have

Related object: L<AdministratorDB::Schema::Result::ContainerAccess>

=cut

__PACKAGE__->might_have(
  "container_access",
  "AdministratorDB::Schema::Result::ContainerAccess",
  { "foreign.container_access_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 data_model

Type: might_have

Related object: L<AdministratorDB::Schema::Result::DataModel>

=cut

__PACKAGE__->might_have(
  "data_model",
  "AdministratorDB::Schema::Result::DataModel",
  { "foreign.data_model_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entity_comment

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::EntityComment>

=cut

__PACKAGE__->belongs_to(
  "entity_comment",
  "AdministratorDB::Schema::Result::EntityComment",
  { entity_comment_id => "entity_comment_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 entity_lock_consumers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::EntityLock>

=cut

__PACKAGE__->has_many(
  "entity_lock_consumers",
  "AdministratorDB::Schema::Result::EntityLock",
  { "foreign.consumer_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entity_lock_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::EntityLock>

=cut

__PACKAGE__->might_have(
  "entity_lock_entity",
  "AdministratorDB::Schema::Result::EntityLock",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entityright_entityright_consumers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Entityright>

=cut

__PACKAGE__->has_many(
  "entityright_entityright_consumers",
  "AdministratorDB::Schema::Result::Entityright",
  { "foreign.entityright_consumer_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entityright_entityrights_consumed

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Entityright>

=cut

__PACKAGE__->has_many(
  "entityright_entityrights_consumed",
  "AdministratorDB::Schema::Result::Entityright",
  { "foreign.entityright_consumed_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gp

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Gp>

=cut

__PACKAGE__->might_have(
  "gp",
  "AdministratorDB::Schema::Result::Gp",
  { "foreign.gp_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 host

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->might_have(
  "host",
  "AdministratorDB::Schema::Result::Host",
  { "foreign.host_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hostmodel

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Hostmodel>

=cut

__PACKAGE__->might_have(
  "hostmodel",
  "AdministratorDB::Schema::Result::Hostmodel",
  { "foreign.hostmodel_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 iface

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Iface>

=cut

__PACKAGE__->might_have(
  "iface",
  "AdministratorDB::Schema::Result::Iface",
  { "foreign.iface_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Indicator>

=cut

__PACKAGE__->might_have(
  "indicator",
  "AdministratorDB::Schema::Result::Indicator",
  { "foreign.indicator_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ingroups

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Ingroup>

=cut

__PACKAGE__->has_many(
  "ingroups",
  "AdministratorDB::Schema::Result::Ingroup",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 interface

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Interface>

=cut

__PACKAGE__->might_have(
  "interface",
  "AdministratorDB::Schema::Result::Interface",
  { "foreign.interface_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 kernel

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Kernel>

=cut

__PACKAGE__->might_have(
  "kernel",
  "AdministratorDB::Schema::Result::Kernel",
  { "foreign.kernel_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 masterimage

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Masterimage>

=cut

__PACKAGE__->might_have(
  "masterimage",
  "AdministratorDB::Schema::Result::Masterimage",
  { "foreign.masterimage_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netapp_aggregate

Type: might_have

Related object: L<AdministratorDB::Schema::Result::NetappAggregate>

=cut

__PACKAGE__->might_have(
  "netapp_aggregate",
  "AdministratorDB::Schema::Result::NetappAggregate",
  { "foreign.aggregate_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netconf

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Netconf>

=cut

__PACKAGE__->might_have(
  "netconf",
  "AdministratorDB::Schema::Result::Netconf",
  { "foreign.netconf_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netconf_role

Type: might_have

Related object: L<AdministratorDB::Schema::Result::NetconfRole>

=cut

__PACKAGE__->might_have(
  "netconf_role",
  "AdministratorDB::Schema::Result::NetconfRole",
  { "foreign.netconf_role_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 network

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Network>

=cut

__PACKAGE__->might_have(
  "network",
  "AdministratorDB::Schema::Result::Network",
  { "foreign.network_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nfs_container_access_client

Type: might_have

Related object: L<AdministratorDB::Schema::Result::NfsContainerAccessClient>

=cut

__PACKAGE__->might_have(
  "nfs_container_access_client",
  "AdministratorDB::Schema::Result::NfsContainerAccessClient",
  { "foreign.nfs_container_access_client_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_condition

Type: might_have

Related object: L<AdministratorDB::Schema::Result::NodemetricCondition>

=cut

__PACKAGE__->might_have(
  "nodemetric_condition",
  "AdministratorDB::Schema::Result::NodemetricCondition",
  { "foreign.nodemetric_condition_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 notification_subscription_entities

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NotificationSubscription>

=cut

__PACKAGE__->has_many(
  "notification_subscription_entities",
  "AdministratorDB::Schema::Result::NotificationSubscription",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 notification_subscription_subscribers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NotificationSubscription>

=cut

__PACKAGE__->has_many(
  "notification_subscription_subscribers",
  "AdministratorDB::Schema::Result::NotificationSubscription",
  { "foreign.subscriber_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 operation

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Operation>

=cut

__PACKAGE__->might_have(
  "operation",
  "AdministratorDB::Schema::Result::Operation",
  { "foreign.operation_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 policy

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Policy>

=cut

__PACKAGE__->might_have(
  "policy",
  "AdministratorDB::Schema::Result::Policy",
  { "foreign.policy_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 poolip

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Poolip>

=cut

__PACKAGE__->might_have(
  "poolip",
  "AdministratorDB::Schema::Result::Poolip",
  { "foreign.poolip_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 processormodel

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Processormodel>

=cut

__PACKAGE__->might_have(
  "processormodel",
  "AdministratorDB::Schema::Result::Processormodel",
  { "foreign.processormodel_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 repository

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Repository>

=cut

__PACKAGE__->might_have(
  "repository",
  "AdministratorDB::Schema::Result::Repository",
  { "foreign.repository_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rule

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Rule>

=cut

__PACKAGE__->might_have(
  "rule",
  "AdministratorDB::Schema::Result::Rule",
  { "foreign.rule_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider

Type: might_have

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->might_have(
  "service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { "foreign.service_provider_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_template

Type: might_have

Related object: L<AdministratorDB::Schema::Result::ServiceTemplate>

=cut

__PACKAGE__->might_have(
  "service_template",
  "AdministratorDB::Schema::Result::ServiceTemplate",
  { "foreign.service_template_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 systemimage

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Systemimage>

=cut

__PACKAGE__->might_have(
  "systemimage",
  "AdministratorDB::Schema::Result::Systemimage",
  { "foreign.systemimage_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user

Type: might_have

Related object: L<AdministratorDB::Schema::Result::User>

=cut

__PACKAGE__->might_have(
  "user",
  "AdministratorDB::Schema::Result::User",
  { "foreign.user_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vlan

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Vlan>

=cut

__PACKAGE__->might_have(
  "vlan",
  "AdministratorDB::Schema::Result::Vlan",
  { "foreign.vlan_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow_def

Type: might_have

Related object: L<AdministratorDB::Schema::Result::WorkflowDef>

=cut

__PACKAGE__->might_have(
  "workflow_def",
  "AdministratorDB::Schema::Result::WorkflowDef",
  { "foreign.workflow_def_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow_workflow

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Workflow>

=cut

__PACKAGE__->might_have(
  "workflow_workflow",
  "AdministratorDB::Schema::Result::Workflow",
  { "foreign.workflow_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflows_related

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Workflow>

=cut

__PACKAGE__->has_many(
  "workflows_related",
  "AdministratorDB::Schema::Result::Workflow",
  { "foreign.related_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gps

Type: many_to_many

Composing rels: L</ingroups> -> gp

=cut

__PACKAGE__->many_to_many("gps", "ingroups", "gp");


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-02-21 17:12:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IDXik1wM1YaBKXKaGbXCcw

__PACKAGE__->might_have(
  "workflow",
  "AdministratorDB::Schema::Result::Workflow",
  { "foreign.workflow_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->might_have(
  "collector_indicator",
  "AdministratorDB::Schema::Result::CollectorIndicator",
  { "foreign.collector_indicator_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "collector_indicators",
  "AdministratorDB::Schema::Result::CollectorIndicator",
  { "foreign.collector_manager_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

# LEGACY
__PACKAGE__->has_many(
  "alerts",
  "AdministratorDB::Schema::Result::Alert",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


1;
