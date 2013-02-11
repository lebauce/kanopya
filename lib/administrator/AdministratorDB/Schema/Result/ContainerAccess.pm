use utf8;
package AdministratorDB::Schema::Result::ContainerAccess;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::ContainerAccess

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

=head1 TABLE: C<container_access>

=cut

__PACKAGE__->table("container_access");

=head1 ACCESSORS

=head2 container_access_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 container_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 container_access_export

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 container_access_ip

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 container_access_port

  data_type: 'integer'
  is_nullable: 0

=head2 device_connected

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 partition_connected

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 export_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "container_access_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "container_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "container_access_export",
  { data_type => "char", is_nullable => 0, size => 255 },
  "container_access_ip",
  { data_type => "char", is_nullable => 0, size => 15 },
  "container_access_port",
  { data_type => "integer", is_nullable => 0 },
  "device_connected",
  { data_type => "char", default_value => "", is_nullable => 0, size => 255 },
  "partition_connected",
  { data_type => "char", default_value => "", is_nullable => 0, size => 255 },
  "export_manager_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</container_access_id>

=back

=cut

__PACKAGE__->set_primary_key("container_access_id");

=head1 RELATIONS

=head2 container

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Container>

=cut

__PACKAGE__->belongs_to(
  "container",
  "AdministratorDB::Schema::Result::Container",
  { container_id => "container_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 container_access

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "container_access",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "container_access_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 export_manager

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "export_manager",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "export_manager_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 file_container_access

Type: might_have

Related object: L<AdministratorDB::Schema::Result::FileContainerAccess>

=cut

__PACKAGE__->might_have(
  "file_container_access",
  "AdministratorDB::Schema::Result::FileContainerAccess",
  {
    "foreign.file_container_access_id" => "self.container_access_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 file_containers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::FileContainer>

=cut

__PACKAGE__->has_many(
  "file_containers",
  "AdministratorDB::Schema::Result::FileContainer",
  { "foreign.container_access_id" => "self.container_access_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 iscsi_container_access

Type: might_have

Related object: L<AdministratorDB::Schema::Result::IscsiContainerAccess>

=cut

__PACKAGE__->might_have(
  "iscsi_container_access",
  "AdministratorDB::Schema::Result::IscsiContainerAccess",
  {
    "foreign.iscsi_container_access_id" => "self.container_access_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 local_container_access

Type: might_have

Related object: L<AdministratorDB::Schema::Result::LocalContainerAccess>

=cut

__PACKAGE__->might_have(
  "local_container_access",
  "AdministratorDB::Schema::Result::LocalContainerAccess",
  {
    "foreign.local_container_access_id" => "self.container_access_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nfs_container_access

Type: might_have

Related object: L<AdministratorDB::Schema::Result::NfsContainerAccess>

=cut

__PACKAGE__->might_have(
  "nfs_container_access",
  "AdministratorDB::Schema::Result::NfsContainerAccess",
  { "foreign.nfs_container_access_id" => "self.container_access_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 opennebula3_repositories

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Opennebula3Repository>

=cut

__PACKAGE__->has_many(
  "opennebula3_repositories",
  "AdministratorDB::Schema::Result::Opennebula3Repository",
  { "foreign.container_access_id" => "self.container_access_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 systemimage_container_accesses

Type: has_many

Related object: L<AdministratorDB::Schema::Result::SystemimageContainerAccess>

=cut

__PACKAGE__->has_many(
  "systemimage_container_accesses",
  "AdministratorDB::Schema::Result::SystemimageContainerAccess",
  { "foreign.container_access_id" => "self.container_access_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vsphere5_repositories

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Vsphere5Repository>

=cut

__PACKAGE__->has_many(
  "vsphere5_repositories",
  "AdministratorDB::Schema::Result::Vsphere5Repository",
  { "foreign.container_access_id" => "self.container_access_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 systemimages

Type: many_to_many

Composing rels: L</systemimage_container_accesses> -> systemimage

=cut

__PACKAGE__->many_to_many(
  "systemimages",
  "systemimage_container_accesses",
  "systemimage",
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-02-11 10:57:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sYk5kgpeawPIBaD27BlEeA

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "container_access_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
