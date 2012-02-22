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

=head2 export_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 client_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nfs_container_access_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "export_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "client_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
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


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-02-22 15:12:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xkykyepCI2knc5/rmUvF1Q

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::ContainerAccess",
  { "foreign.container_access_id" => "self.nfs_container_access_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
