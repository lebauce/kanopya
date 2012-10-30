use utf8;
package AdministratorDB::Schema::Result::Combination;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Combination

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<combination>

=cut

__PACKAGE__->table("combination");

=head1 ACCESSORS

=head2 combination_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 class_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "combination_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "class_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
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

Related object: L<AdministratorDB::Schema::Result::AggregateCombination>

=cut

__PACKAGE__->might_have(
  "aggregate_combination",
  "AdministratorDB::Schema::Result::AggregateCombination",
  { "foreign.aggregate_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 aggregate_condition_left_combinations

Type: has_many

Related object: L<AdministratorDB::Schema::Result::AggregateCondition>

=cut

__PACKAGE__->has_many(
  "aggregate_condition_left_combinations",
  "AdministratorDB::Schema::Result::AggregateCondition",
  { "foreign.left_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 aggregate_condition_right_combinations

Type: has_many

Related object: L<AdministratorDB::Schema::Result::AggregateCondition>

=cut

__PACKAGE__->has_many(
  "aggregate_condition_right_combinations",
  "AdministratorDB::Schema::Result::AggregateCondition",
  { "foreign.right_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 class_type

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ClassType>

=cut

__PACKAGE__->belongs_to(
  "class_type",
  "AdministratorDB::Schema::Result::ClassType",
  { class_type_id => "class_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 constant_combination

Type: might_have

Related object: L<AdministratorDB::Schema::Result::ConstantCombination>

=cut

__PACKAGE__->might_have(
  "constant_combination",
  "AdministratorDB::Schema::Result::ConstantCombination",
  { "foreign.constant_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_combination

Type: might_have

Related object: L<AdministratorDB::Schema::Result::NodemetricCombination>

=cut

__PACKAGE__->might_have(
  "nodemetric_combination",
  "AdministratorDB::Schema::Result::NodemetricCombination",
  { "foreign.nodemetric_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_condition_right_combinations

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NodemetricCondition>

=cut

__PACKAGE__->has_many(
  "nodemetric_condition_right_combinations",
  "AdministratorDB::Schema::Result::NodemetricCondition",
  { "foreign.right_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_conditions

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NodemetricCondition>

=cut

__PACKAGE__->has_many(
  "nodemetric_condition_left_combinations",
  "AdministratorDB::Schema::Result::NodemetricCondition",
  { "foreign.left_combination_id" => "self.combination_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-10-29 15:45:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4TP+/K9pvNXvI0ABndNotQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
