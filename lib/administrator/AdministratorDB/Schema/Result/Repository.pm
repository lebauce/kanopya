use utf8;
package AdministratorDB::Schema::Result::Repository;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Repository

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

=head1 TABLE: C<repository>

=cut

__PACKAGE__->table("repository");

=head1 ACCESSORS

=head2 repository_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 virtualization_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 container_access_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 repository_name

  data_type: 'char'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "repository_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "virtualization_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "container_access_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "repository_name",
  { data_type => "char", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</repository_id>

=back

=cut

__PACKAGE__->set_primary_key("repository_id");

=head1 RELATIONS

=head2 opennebula3_repository

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Opennebula3Repository>

=cut

__PACKAGE__->might_have(
  "opennebula3_repository",
  "AdministratorDB::Schema::Result::Opennebula3Repository",
  { "foreign.opennebula3_repository_id" => "self.repository_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

=head2 repository

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "repository",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "repository_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 virtualization

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Virtualization>

=cut

__PACKAGE__->belongs_to(
  "virtualization",
  "AdministratorDB::Schema::Result::Virtualization",
  { virtualization_id => "virtualization_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-02-26 16:10:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4dJnsuHSe3cNGEA990btlA

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "repository_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
