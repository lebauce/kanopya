use utf8;
package Kanopya::Schema::Result::NodemetricCondition;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::NodemetricCondition

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

=head1 TABLE: C<nodemetric_condition>

=cut

__PACKAGE__->table("nodemetric_condition");

=head1 ACCESSORS

=head2 nodemetric_condition_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 nodemetric_condition_label

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 nodemetric_condition_service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 left_combination_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 right_combination_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 nodemetric_condition_comparator

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 nodemetric_condition_formula_string

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "nodemetric_condition_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "nodemetric_condition_label",
  { data_type => "char", is_nullable => 1, size => 255 },
  "nodemetric_condition_service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "left_combination_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "right_combination_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "nodemetric_condition_comparator",
  { data_type => "char", is_nullable => 0, size => 32 },
  "nodemetric_condition_formula_string",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</nodemetric_condition_id>

=back

=cut

__PACKAGE__->set_primary_key("nodemetric_condition_id");

=head1 RELATIONS

=head2 left_combination

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Combination>

=cut

__PACKAGE__->belongs_to(
  "left_combination",
  "Kanopya::Schema::Result::Combination",
  { combination_id => "left_combination_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 nodemetric_condition

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "nodemetric_condition",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "nodemetric_condition_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 nodemetric_condition_service_provider

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "nodemetric_condition_service_provider",
  "Kanopya::Schema::Result::ServiceProvider",
  {
    service_provider_id => "nodemetric_condition_service_provider_id",
  },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 right_combination

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Combination>

=cut

__PACKAGE__->belongs_to(
  "right_combination",
  "Kanopya::Schema::Result::Combination",
  { combination_id => "right_combination_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:syGe7U09HSmWsMAR2sybEQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
