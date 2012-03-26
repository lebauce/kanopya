package AdministratorDB::Schema::Result::NfsContainerAccessClient;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::NfsContainerAccessClient

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
__PACKAGE__->set_primary_key("nfs_container_access_client_id");

=head1 RELATIONS

=head2 nfs_container_access_client

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "nfs_container_access_client",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "nfs_container_access_client_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 nfs_container_access

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::NfsContainerAccess>

=cut

__PACKAGE__->belongs_to(
  "nfs_container_access",
  "AdministratorDB::Schema::Result::NfsContainerAccess",
  { nfs_container_access_id => "nfs_container_access_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-03-15 10:15:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EYegXGmelNwxS4eWozkskg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.entity_id" => "self.nfs_container_access_client_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
