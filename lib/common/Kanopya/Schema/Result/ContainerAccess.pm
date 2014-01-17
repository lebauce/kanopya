use utf8;
package Kanopya::Schema::Result::ContainerAccess;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::ContainerAccess

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

Related object: L<Kanopya::Schema::Result::Container>

=cut

__PACKAGE__->belongs_to(
  "container",
  "Kanopya::Schema::Result::Container",
  { container_id => "container_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 container_access

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "container_access",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "container_access_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 export_manager

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "export_manager",
  "Kanopya::Schema::Result::Component",
  { component_id => "export_manager_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 file_container_access

Type: might_have

Related object: L<Kanopya::Schema::Result::FileContainerAccess>

=cut

__PACKAGE__->might_have(
  "file_container_access",
  "Kanopya::Schema::Result::FileContainerAccess",
  {
    "foreign.file_container_access_id" => "self.container_access_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 file_containers

Type: has_many

Related object: L<Kanopya::Schema::Result::FileContainer>

=cut

__PACKAGE__->has_many(
  "file_containers",
  "Kanopya::Schema::Result::FileContainer",
  { "foreign.container_access_id" => "self.container_access_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 iscsi_container_access

Type: might_have

Related object: L<Kanopya::Schema::Result::IscsiContainerAccess>

=cut

__PACKAGE__->might_have(
  "iscsi_container_access",
  "Kanopya::Schema::Result::IscsiContainerAccess",
  {
    "foreign.iscsi_container_access_id" => "self.container_access_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 local_container_access

Type: might_have

Related object: L<Kanopya::Schema::Result::LocalContainerAccess>

=cut

__PACKAGE__->might_have(
  "local_container_access",
  "Kanopya::Schema::Result::LocalContainerAccess",
  {
    "foreign.local_container_access_id" => "self.container_access_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nfs_container_access

Type: might_have

Related object: L<Kanopya::Schema::Result::NfsContainerAccess>

=cut

__PACKAGE__->might_have(
  "nfs_container_access",
  "Kanopya::Schema::Result::NfsContainerAccess",
  { "foreign.nfs_container_access_id" => "self.container_access_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 repositories

Type: has_many

Related object: L<Kanopya::Schema::Result::Repository>

=cut

__PACKAGE__->has_many(
  "repositories",
  "Kanopya::Schema::Result::Repository",
  { "foreign.container_access_id" => "self.container_access_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 systemimage_container_accesses

Type: has_many

Related object: L<Kanopya::Schema::Result::SystemimageContainerAccess>

=cut

__PACKAGE__->has_many(
  "systemimage_container_accesses",
  "Kanopya::Schema::Result::SystemimageContainerAccess",
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


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:B2DHOQFrvG7u7YJUVwZTqA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
