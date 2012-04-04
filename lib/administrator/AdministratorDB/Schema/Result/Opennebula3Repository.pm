package AdministratorDB::Schema::Result::Opennebula3Repository;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Opennebula3Repository

=cut

__PACKAGE__->table("opennebula3_repository");

=head1 ACCESSORS

=head2 opennebula3_repository_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 opennebula3_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 repository_name

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 container_access_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "opennebula3_repository_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "opennebula3_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "repository_name",
  { data_type => "char", is_nullable => 0, size => 255 },
  "container_access_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("opennebula3_repository_id");

=head1 RELATIONS

=head2 opennebula3

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Opennebula3>

=cut

__PACKAGE__->belongs_to(
  "opennebula3",
  "AdministratorDB::Schema::Result::Opennebula3",
  { opennebula3_id => "opennebula3_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 container_access

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ContainerAccess>

=cut

__PACKAGE__->belongs_to(
  "container_access",
  "AdministratorDB::Schema::Result::ContainerAccess",
  { container_access_id => "container_access_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-04-03 12:59:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6U28krv7+udZRPzjlCuu1A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
