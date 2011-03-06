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

=head2 cluster_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::ClusterEntity>

=cut

__PACKAGE__->might_have(
  "cluster_entity",
  "AdministratorDB::Schema::Result::ClusterEntity",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 component_instance_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::ComponentInstanceEntity>

=cut

__PACKAGE__->might_have(
  "component_instance_entity",
  "AdministratorDB::Schema::Result::ComponentInstanceEntity",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 distribution_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::DistributionEntity>

=cut

__PACKAGE__->might_have(
  "distribution_entity",
  "AdministratorDB::Schema::Result::DistributionEntity",
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

=head2 gp_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::GpEntity>

=cut

__PACKAGE__->might_have(
  "gp_entity",
  "AdministratorDB::Schema::Result::GpEntity",
  { "foreign.entity_id" => "self.entity_id" },
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

=head2 kernel_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::KernelEntity>

=cut

__PACKAGE__->might_have(
  "kernel_entity",
  "AdministratorDB::Schema::Result::KernelEntity",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 message_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::MessageEntity>

=cut

__PACKAGE__->might_have(
  "message_entity",
  "AdministratorDB::Schema::Result::MessageEntity",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 motherboard_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::MotherboardEntity>

=cut

__PACKAGE__->might_have(
  "motherboard_entity",
  "AdministratorDB::Schema::Result::MotherboardEntity",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 motherboardmodel_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::MotherboardmodelEntity>

=cut

__PACKAGE__->might_have(
  "motherboardmodel_entity",
  "AdministratorDB::Schema::Result::MotherboardmodelEntity",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 operation_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::OperationEntity>

=cut

__PACKAGE__->might_have(
  "operation_entity",
  "AdministratorDB::Schema::Result::OperationEntity",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 operationtype_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::OperationtypeEntity>

=cut

__PACKAGE__->might_have(
  "operationtype_entity",
  "AdministratorDB::Schema::Result::OperationtypeEntity",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 powersupplycard_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::PowersupplycardEntity>

=cut

__PACKAGE__->might_have(
  "powersupplycard_entity",
  "AdministratorDB::Schema::Result::PowersupplycardEntity",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 powersupplycardmodel_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::PowersupplycardmodelEntity>

=cut

__PACKAGE__->might_have(
  "powersupplycardmodel_entity",
  "AdministratorDB::Schema::Result::PowersupplycardmodelEntity",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 processormodel_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::ProcessormodelEntity>

=cut

__PACKAGE__->might_have(
  "processormodel_entity",
  "AdministratorDB::Schema::Result::ProcessormodelEntity",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 systemimage_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::SystemimageEntity>

=cut

__PACKAGE__->might_have(
  "systemimage_entity",
  "AdministratorDB::Schema::Result::SystemimageEntity",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::UserEntity>

=cut

__PACKAGE__->might_have(
  "user_entity",
  "AdministratorDB::Schema::Result::UserEntity",
  { "foreign.entity_id" => "self.entity_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-27 08:08:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ba6T8h4r+C2/B4/RwxIPlA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
