package AdministratorDB::Schema::Result::FileContainerAccess;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::FileContainerAccess

=cut

__PACKAGE__->table("file_container_access");

=head1 ACCESSORS

=head2 file_container_access_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "file_container_access_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("file_container_access_id");

=head1 RELATIONS

=head2 file_container_access

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ContainerAccess>

=cut

__PACKAGE__->belongs_to(
  "file_container_access",
  "AdministratorDB::Schema::Result::ContainerAccess",
  { container_access_id => "file_container_access_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-03-15 13:22:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KTx8iNStnloTZtY9eCz4lg

__PACKAGE__->belongs_to(
   "parent",
   "AdministratorDB::Schema::Result::ContainerAccess",
   { "foreign.container_access_id" => "self.file_container_access_id" },
   { cascade_copy => 0, cascade_delete => 1 }
);

1;
