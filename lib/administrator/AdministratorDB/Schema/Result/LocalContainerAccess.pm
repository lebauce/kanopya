package AdministratorDB::Schema::Result::LocalContainerAccess;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::LocalContainerAccess

=cut

__PACKAGE__->table("local_container_access");

=head1 ACCESSORS

=head2 local_container_access_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 file_path

  data_type: 'char'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "local_container_access_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "file_path",
  { data_type => "char", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("local_container_access_id");

=head1 RELATIONS

=head2 local_container_access

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ContainerAccess>

=cut

__PACKAGE__->belongs_to(
  "local_container_access",
  "AdministratorDB::Schema::Result::ContainerAccess",
  { container_access_id => "local_container_access_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-02-16 20:32:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zrsNOLftDcqfWL7+jB9euA

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::ContainerAccess",
  { "foreign.container_access_id" => "self.local_container_access_id" },
  { cascade_copy => 0, cascade_delete => 1 });

1;
