use utf8;
package Kanopya::Schema::Result::NfsContainerAccessClient;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::NfsContainerAccessClient

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

=head1 TABLE: C<nfs_container_access_client>

=cut

__PACKAGE__->table("nfs_container_access_client");

=head1 ACCESSORS

=head2 nfs_container_access_client_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 options

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 nfs_container_access_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nfs_container_access_client_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "char", is_nullable => 0, size => 255 },
  "options",
  { data_type => "char", is_nullable => 0, size => 255 },
  "nfs_container_access_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</nfs_container_access_client_id>

=back

=cut

__PACKAGE__->set_primary_key("nfs_container_access_client_id");

=head1 RELATIONS

=head2 nfs_container_access

Type: belongs_to

Related object: L<Kanopya::Schema::Result::NfsContainerAccess>

=cut

__PACKAGE__->belongs_to(
  "nfs_container_access",
  "Kanopya::Schema::Result::NfsContainerAccess",
  { nfs_container_access_id => "nfs_container_access_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 nfs_container_access_client

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "nfs_container_access_client",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "nfs_container_access_client_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:h82yOSkoalDzVUHBUfM/nw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
