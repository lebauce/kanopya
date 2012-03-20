package AdministratorDB::Schema::Result::ContainerAccess;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ContainerAccess

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
  is_nullable: 0

=head2 export_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
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
    is_nullable => 0,
  },
  "export_manager_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "device_connected",
  { data_type => "char", default_value => "", is_nullable => 0, size => 255 },
  "partition_connected",
  { data_type => "char", default_value => "", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("container_access_id");

=head1 RELATIONS

=head2 container_access

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "container_access",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "container_access_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 container

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Container>

=cut

__PACKAGE__->belongs_to(
  "container",
  "AdministratorDB::Schema::Result::Container",
  { container_id => "container_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
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


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-03-20 12:39:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fjzafSG/6HmZUxPQ71pbzg
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.entity_id" => "self.container_access_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
