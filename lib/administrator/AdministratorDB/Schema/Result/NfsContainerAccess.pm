package AdministratorDB::Schema::Result::NfsContainerAccess;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::NfsContainerAccess

=cut

__PACKAGE__->table("nfs_container_access");

=head1 ACCESSORS

=head2 nfs_container_access_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 export_path

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
  "export_path",
  { data_type => "char", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("nfs_container_access_id");

=head1 RELATIONS

=head2 nfs_container_access

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ContainerAccess>

=cut

__PACKAGE__->belongs_to(
  "nfs_container_access",
  "AdministratorDB::Schema::Result::ContainerAccess",
  { container_access_id => "nfs_container_access_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 nfs_container_access_clients

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NfsContainerAccessClient>

=cut

__PACKAGE__->has_many(
  "nfs_container_access_clients",
  "AdministratorDB::Schema::Result::NfsContainerAccessClient",
  {
    "foreign.nfs_container_access_id" => "self.nfs_container_access_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-03-14 19:05:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AQBmVVJKvycjWI92h43mhA

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::ContainerAccess",
  { "foreign.container_access_id" => "self.nfs_container_access_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
