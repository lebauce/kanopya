use utf8;
package AdministratorDB::Schema::Result::Kanopyaworkflow0;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Kanopyaworkflow0

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

=head1 TABLE: C<kanopyaworkflow0>

=cut

__PACKAGE__->table("kanopyaworkflow0");

=head1 ACCESSORS

=head2 kanopyaworkflow_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "kanopyaworkflow_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</kanopyaworkflow_id>

=back

=cut

__PACKAGE__->set_primary_key("kanopyaworkflow_id");

=head1 RELATIONS

=head2 kanopyaworkflow

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "kanopyaworkflow",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "kanopyaworkflow_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-03-27 16:05:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e6zm40fj7FQF635vkMHUkg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Component",
  { component_id => "kanopyaworkflow_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
