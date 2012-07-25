package AdministratorDB::Schema::Result::Entity;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Entity

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
__PACKAGE__->set_primary_key("entity_id");

=head1 RELATIONS

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

=head2 connector

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Connector>

=cut

__PACKAGE__->might_have(
  "connector",
  "AdministratorDB::Schema::Result::Connector",
  { "foreign.connector_id" => "self.entity_id" },
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

=head2 entity_lock

Type: might_have

Related object: L<AdministratorDB::Schema::Result::EntityLock>

=cut

__PACKAGE__->might_have(
  "entity_lock",
  "AdministratorDB::Schema::Result::EntityLock",
  { "foreign.entity_id" => "self.entity_id" },
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

=head2 infrastructure

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Infrastructure>

=cut

__PACKAGE__->might_have(
  "infrastructure",
  "AdministratorDB::Schema::Result::Infrastructure",
  { "foreign.infrastructure_id" => "self.entity_id" },
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

=head2 interface_role

Type: might_have

Related object: L<AdministratorDB::Schema::Result::InterfaceRole>

=cut

__PACKAGE__->might_have(
  "interface_role",
  "AdministratorDB::Schema::Result::InterfaceRole",
  { "foreign.interface_role_id" => "self.entity_id" },
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

=head2 powersupplycard

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Powersupplycard>

=cut

__PACKAGE__->might_have(
  "powersupplycard",
  "AdministratorDB::Schema::Result::Powersupplycard",
  { "foreign.powersupplycard_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 powersupplycardmodel

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Powersupplycardmodel>

=cut

__PACKAGE__->might_have(
  "powersupplycardmodel",
  "AdministratorDB::Schema::Result::Powersupplycardmodel",
  { "foreign.powersupplycardmodel_id" => "self.entity_id" },
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

=head2 tier

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Tier>

=cut

__PACKAGE__->might_have(
  "tier",
  "AdministratorDB::Schema::Result::Tier",
  { "foreign.tier_id" => "self.entity_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-07-18 11:47:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:I9VZtZzRag/M+kp+7fswTw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
