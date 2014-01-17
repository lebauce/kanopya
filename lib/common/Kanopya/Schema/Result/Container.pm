use utf8;
package Kanopya::Schema::Result::Container;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Container

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

=head1 TABLE: C<container>

=cut

__PACKAGE__->table("container");

=head1 ACCESSORS

=head2 container_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 container_name

  data_type: 'char'
  is_nullable: 0
  size: 128

=head2 container_size

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 container_device

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 container_filesystem

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 container_freespace

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 disk_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "container_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "container_name",
  { data_type => "char", is_nullable => 0, size => 128 },
  "container_size",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 0 },
  "container_device",
  { data_type => "char", is_nullable => 0, size => 255 },
  "container_filesystem",
  { data_type => "char", is_nullable => 0, size => 32 },
  "container_freespace",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "disk_manager_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</container_id>

=back

=cut

__PACKAGE__->set_primary_key("container_id");

=head1 RELATIONS

=head2 container

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "container",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "container_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 container_accesses

Type: has_many

Related object: L<Kanopya::Schema::Result::ContainerAccess>

=cut

__PACKAGE__->has_many(
  "container_accesses",
  "Kanopya::Schema::Result::ContainerAccess",
  { "foreign.container_id" => "self.container_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 disk_manager

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "disk_manager",
  "Kanopya::Schema::Result::Component",
  { component_id => "disk_manager_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 file_container

Type: might_have

Related object: L<Kanopya::Schema::Result::FileContainer>

=cut

__PACKAGE__->might_have(
  "file_container",
  "Kanopya::Schema::Result::FileContainer",
  { "foreign.file_container_id" => "self.container_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 local_container

Type: might_have

Related object: L<Kanopya::Schema::Result::LocalContainer>

=cut

__PACKAGE__->might_have(
  "local_container",
  "Kanopya::Schema::Result::LocalContainer",
  { "foreign.local_container_id" => "self.container_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 lvm_container

Type: might_have

Related object: L<Kanopya::Schema::Result::LvmContainer>

=cut

__PACKAGE__->might_have(
  "lvm_container",
  "Kanopya::Schema::Result::LvmContainer",
  { "foreign.lvm_container_id" => "self.container_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netapp_lun

Type: might_have

Related object: L<Kanopya::Schema::Result::NetappLun>

=cut

__PACKAGE__->might_have(
  "netapp_lun",
  "Kanopya::Schema::Result::NetappLun",
  { "foreign.lun_id" => "self.container_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netapp_volume

Type: might_have

Related object: L<Kanopya::Schema::Result::NetappVolume>

=cut

__PACKAGE__->might_have(
  "netapp_volume",
  "Kanopya::Schema::Result::NetappVolume",
  { "foreign.volume_id" => "self.container_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LX/qhH4p7MmQdS4xN5eXGg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
