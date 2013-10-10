use utf8;
package AdministratorDB::Schema::Result::OpenstackRepository;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::OpenstackRepository

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

=head1 TABLE: C<openstack_repository>

=cut

__PACKAGE__->table("openstack_repository");

=head1 ACCESSORS

=head2 openstack_repository_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "openstack_repository_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</openstack_repository_id>

=back

=cut

__PACKAGE__->set_primary_key("openstack_repository_id");

=head1 RELATIONS

=head2 openstack_repository

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Repository>

=cut

__PACKAGE__->belongs_to(
  "openstack_repository",
  "AdministratorDB::Schema::Result::Repository",
  { repository_id => "openstack_repository_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-03-01 11:52:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:11b8EAywPJZGAH78oaH+/A

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Repository",
  { repository_id => "openstack_repository_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
