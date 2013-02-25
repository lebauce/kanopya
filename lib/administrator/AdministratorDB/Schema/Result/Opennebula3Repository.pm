use utf8;
package AdministratorDB::Schema::Result::Opennebula3Repository;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Opennebula3Repository

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

=head1 TABLE: C<opennebula3_repository>

=cut

__PACKAGE__->table("opennebula3_repository");

=head1 ACCESSORS

=head2 opennebula3_repository_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
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

=head2 datastore_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "opennebula3_repository_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
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
  "datastore_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</opennebula3_repository_id>

=back

=cut

__PACKAGE__->set_primary_key("opennebula3_repository_id");

=head1 RELATIONS

=head2 container_access

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ContainerAccess>

=cut

__PACKAGE__->belongs_to(
  "container_access",
  "AdministratorDB::Schema::Result::ContainerAccess",
  { container_access_id => "container_access_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 opennebula3

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Opennebula3>

=cut

__PACKAGE__->belongs_to(
  "opennebula3",
  "AdministratorDB::Schema::Result::Opennebula3",
  { opennebula3_id => "opennebula3_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 opennebula3_repository

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Repository>

=cut

__PACKAGE__->belongs_to(
  "opennebula3_repository",
  "AdministratorDB::Schema::Result::Repository",
  { repository_id => "opennebula3_repository_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-02-25 17:25:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UQ4TFJcAMAndSn+02y7MrA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
