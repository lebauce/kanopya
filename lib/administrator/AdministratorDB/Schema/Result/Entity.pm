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

=cut

__PACKAGE__->add_columns(
  "entity_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("entity_id");

=head1 RELATIONS

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

=head2 distribution

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Distribution>

=cut

__PACKAGE__->might_have(
  "distribution",
  "AdministratorDB::Schema::Result::Distribution",
  { "foreign.distribution_id" => "self.entity_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-02-15 09:20:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3xRCKfRFn4jKj2lQmSl/JQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
