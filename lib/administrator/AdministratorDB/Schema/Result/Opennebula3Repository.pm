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


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-02-26 16:10:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dk17l7fgs/4i3AW7rl/L5g

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Repository",
  { repository_id => "opennebula3_repository_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
