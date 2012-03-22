package AdministratorDB::Schema::Result::IscsiContainerAccess;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::IscsiContainerAccess

=cut

__PACKAGE__->table("iscsi_container_access");

=head1 ACCESSORS

=head2 iscsi_container_access_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 target_name

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 number

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 typeio

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 iomode

  data_type: 'char'
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "iscsi_container_access_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "target_name",
  { data_type => "char", is_nullable => 0, size => 255 },
  "number",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "typeio",
  { data_type => "char", is_nullable => 0, size => 32 },
  "iomode",
  { data_type => "char", is_nullable => 0, size => 16 },
);
__PACKAGE__->set_primary_key("iscsi_container_access_id");

=head1 RELATIONS

=head2 iscsi_container_access

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ContainerAccess>

=cut

__PACKAGE__->belongs_to(
  "iscsi_container_access",
  "AdministratorDB::Schema::Result::ContainerAccess",
  { container_access_id => "iscsi_container_access_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-03-22 16:05:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:02hWvRjHheXEGFA3eoUjFw

__PACKAGE__->belongs_to(
   "parent",
   "AdministratorDB::Schema::Result::ContainerAccess",
   { "foreign.container_access_id" => "self.iscsi_container_access_id" },
   { cascade_copy => 0, cascade_delete => 1 }
);

1;
