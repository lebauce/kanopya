use utf8;
package AdministratorDB::Schema::Result::ConstantCombination;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::ConstantCombination

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

=head1 TABLE: C<constant_combination>

=cut

__PACKAGE__->table("constant_combination");

=head1 ACCESSORS

=head2 constant_combination_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'char'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "constant_combination_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "value",
  { data_type => "char", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</constant_combination_id>

=back

=cut

__PACKAGE__->set_primary_key("constant_combination_id");

=head1 RELATIONS

=head2 constant_combination

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Combination>

=cut

__PACKAGE__->belongs_to(
  "constant_combination",
  "AdministratorDB::Schema::Result::Combination",
  { combination_id => "constant_combination_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-19 12:06:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eNm3xC6Nn9dvakMr1QWymQ
 
__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Combination",
  { combination_id => "constant_combination_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

1;
