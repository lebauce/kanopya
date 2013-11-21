use utf8;
package Kanopya::Schema::Result::NodemetricCombination;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::NodemetricCombination

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

=head1 TABLE: C<nodemetric_combination>

=cut

__PACKAGE__->table("nodemetric_combination");

=head1 ACCESSORS

=head2 nodemetric_combination_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 nodemetric_combination_label

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 nodemetric_combination_formula

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 nodemetric_combination_formula_string

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "nodemetric_combination_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "nodemetric_combination_label",
  { data_type => "char", is_nullable => 1, size => 255 },
  "nodemetric_combination_formula",
  { data_type => "char", is_nullable => 0, size => 255 },
  "nodemetric_combination_formula_string",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</nodemetric_combination_id>

=back

=cut

__PACKAGE__->set_primary_key("nodemetric_combination_id");

=head1 RELATIONS

=head2 nodemetric_combination

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Combination>

=cut

__PACKAGE__->belongs_to(
  "nodemetric_combination",
  "Kanopya::Schema::Result::Combination",
  { combination_id => "nodemetric_combination_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OTAfEGalN78ONQ0TVt2DFw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
