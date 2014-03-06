use utf8;
package Kanopya::Schema::Result::Combination;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Combination

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

=head1 TABLE: C<combination>

=cut

__PACKAGE__->table("combination");

=head1 ACCESSORS

=head2 combination_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 combination_unit

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "combination_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "combination_unit",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</combination_id>

=back

=cut

__PACKAGE__->set_primary_key("combination_id");

=head1 RELATIONS

=head2 aggregate_combination

Type: might_have

Related object: L<Kanopya::Schema::Result::AggregateCombination>

=cut

__PACKAGE__->might_have(
  "aggregate_combination",
  "Kanopya::Schema::Result::AggregateCombination",
  { "foreign.aggregate_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 aggregate_condition_left_combinations

Type: has_many

Related object: L<Kanopya::Schema::Result::AggregateCondition>

=cut

__PACKAGE__->has_many(
  "aggregate_condition_left_combinations",
  "Kanopya::Schema::Result::AggregateCondition",
  { "foreign.left_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 aggregate_condition_right_combinations

Type: has_many

Related object: L<Kanopya::Schema::Result::AggregateCondition>

=cut

__PACKAGE__->has_many(
  "aggregate_condition_right_combinations",
  "Kanopya::Schema::Result::AggregateCondition",
  { "foreign.right_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 combination

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "combination",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "combination_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 constant_combination

Type: might_have

Related object: L<Kanopya::Schema::Result::ConstantCombination>

=cut

__PACKAGE__->might_have(
  "constant_combination",
  "Kanopya::Schema::Result::ConstantCombination",
  { "foreign.constant_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_combination

Type: might_have

Related object: L<Kanopya::Schema::Result::NodemetricCombination>

=cut

__PACKAGE__->might_have(
  "nodemetric_combination",
  "Kanopya::Schema::Result::NodemetricCombination",
  { "foreign.nodemetric_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_condition_left_combinations

Type: has_many

Related object: L<Kanopya::Schema::Result::NodemetricCondition>

=cut

__PACKAGE__->has_many(
  "nodemetric_condition_left_combinations",
  "Kanopya::Schema::Result::NodemetricCondition",
  { "foreign.left_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_condition_right_combinations

Type: has_many

Related object: L<Kanopya::Schema::Result::NodemetricCondition>

=cut

__PACKAGE__->has_many(
  "nodemetric_condition_right_combinations",
  "Kanopya::Schema::Result::NodemetricCondition",
  { "foreign.right_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider

Type: belongs_to

Related object: L<Kanopya::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "Kanopya::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-03-05 18:07:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:g3pqG1g9YI4xm0JG9n8TwA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
