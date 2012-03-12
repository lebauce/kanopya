package AdministratorDB::Schema::Result::Connector;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Connector

=cut

__PACKAGE__->table("connector");

=head1 ACCESSORS

=head2 connector_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 connector_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "connector_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "connector_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("connector_id");

=head1 RELATIONS

=head2 active_directory

Type: might_have

Related object: L<AdministratorDB::Schema::Result::ActiveDirectory>

=cut

__PACKAGE__->might_have(
  "active_directory",
  "AdministratorDB::Schema::Result::ActiveDirectory",
  { "foreign.ad_id" => "self.connector_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 connector

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "connector",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "connector_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Outside>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "AdministratorDB::Schema::Result::Outside",
  { outside_id => "service_provider_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 connector_type

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ConnectorType>

=cut

__PACKAGE__->belongs_to(
  "connector_type",
  "AdministratorDB::Schema::Result::ConnectorType",
  { connector_type_id => "connector_type_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 netapp_lun_manager

Type: might_have

Related object: L<AdministratorDB::Schema::Result::NetappLunManager>

=cut

__PACKAGE__->might_have(
  "netapp_lun_manager",
  "AdministratorDB::Schema::Result::NetappLunManager",
  { "foreign.netapp_lun_manager_id" => "self.connector_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netapp_volume_manager

Type: might_have

Related object: L<AdministratorDB::Schema::Result::NetappVolumeManager>

=cut

__PACKAGE__->might_have(
  "netapp_volume_manager",
  "AdministratorDB::Schema::Result::NetappVolumeManager",
  { "foreign.netapp_volume_manager_id" => "self.connector_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 scom

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Scom>

=cut

__PACKAGE__->might_have(
  "scom",
  "AdministratorDB::Schema::Result::Scom",
  { "foreign.scom_id" => "self.connector_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-03-11 23:10:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BYarYPwy11ipYdAcQF8NMA

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
    { "foreign.entity_id" => "self.connector_id" },
    { cascade_copy => 0, cascade_delete => 1 });

# You can replace this text with custom content, and it will be preserved on regeneration
1;
