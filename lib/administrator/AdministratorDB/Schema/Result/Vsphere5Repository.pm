use utf8;
package AdministratorDB::Schema::Result::Vsphere5Repository;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Vsphere5Repository

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<vsphere5_repository>

=cut

__PACKAGE__->table("vsphere5_repository");

=head1 ACCESSORS

=head2 vsphere5_repository_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 vsphere5_id

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
  "vsphere5_repository_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "vsphere5_id",
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

=head1 PRIMARY KEY

=over 4

=item * L</vsphere5_repository_id>

=back

=cut

__PACKAGE__->set_primary_key("vsphere5_repository_id");

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

=head2 vsphere5

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Vsphere5>

=cut

__PACKAGE__->belongs_to(
  "vsphere5",
  "AdministratorDB::Schema::Result::Vsphere5",
  { vsphere5_id => "vsphere5_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-08-20 17:02:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JKJ+dMiBwg8i02rZNy2SwA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
