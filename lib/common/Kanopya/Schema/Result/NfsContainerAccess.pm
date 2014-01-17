use utf8;
package Kanopya::Schema::Result::NfsContainerAccess;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::NfsContainerAccess

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

=head1 TABLE: C<nfs_container_access>

=cut

__PACKAGE__->table("nfs_container_access");

=head1 ACCESSORS

=head2 nfs_container_access_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 options

  data_type: 'char'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "nfs_container_access_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "options",
  { data_type => "char", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</nfs_container_access_id>

=back

=cut

__PACKAGE__->set_primary_key("nfs_container_access_id");

=head1 RELATIONS

=head2 nfs_container_access

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ContainerAccess>

=cut

__PACKAGE__->belongs_to(
  "nfs_container_access",
  "Kanopya::Schema::Result::ContainerAccess",
  { container_access_id => "nfs_container_access_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 nfs_container_access_clients

Type: has_many

Related object: L<Kanopya::Schema::Result::NfsContainerAccessClient>

=cut

__PACKAGE__->has_many(
  "nfs_container_access_clients",
  "Kanopya::Schema::Result::NfsContainerAccessClient",
  {
    "foreign.nfs_container_access_id" => "self.nfs_container_access_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/vZ/VwwS1WQaqk9EpW3SjA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
