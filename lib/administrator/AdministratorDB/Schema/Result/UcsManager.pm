use utf8;
package AdministratorDB::Schema::Result::UcsManager;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::UcsManager

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

=head1 TABLE: C<ucs_manager>

=cut

__PACKAGE__->table("ucs_manager");

=head1 ACCESSORS

=head2 ucs_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "ucs_manager_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</ucs_manager_id>

=back

=cut

__PACKAGE__->set_primary_key("ucs_manager_id");

=head1 RELATIONS

=head2 ucs_manager

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "ucs_manager",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "ucs_manager_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-01-31 11:35:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MrTuChAvJtqmrQCP80YWjQ

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "ucs_manager_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
