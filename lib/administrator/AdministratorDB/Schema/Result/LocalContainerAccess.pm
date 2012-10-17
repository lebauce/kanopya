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

=cut

__PACKAGE__->add_columns(
  "local_container_access_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
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
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-10-16 11:49:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:amTDXZ3uBB4jWiFOND5zmA

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::ContainerAccess",
  { container_access_id => "local_container_access_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
