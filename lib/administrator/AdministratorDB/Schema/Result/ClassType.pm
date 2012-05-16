use utf8;
package AdministratorDB::Schema::Result::ClassType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::ClassType

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<class_type>

=cut

__PACKAGE__->table("class_type");

=head1 ACCESSORS

=head2 class_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 class_type

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "class_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "class_type",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</class_type_id>

=back

=cut

__PACKAGE__->set_primary_key("class_type_id");

=head1 RELATIONS

=head2 action_parameters

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ActionParameter>

=cut

__PACKAGE__->has_many(
  "action_parameters",
  "AdministratorDB::Schema::Result::ActionParameter",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 action_type_parameters

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ActionTypeParameter>

=cut

__PACKAGE__->has_many(
  "action_type_parameters",
  "AdministratorDB::Schema::Result::ActionTypeParameter",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 action_types

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ActionType>

=cut

__PACKAGE__->has_many(
  "action_types",
  "AdministratorDB::Schema::Result::ActionType",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 actions

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Action>

=cut

__PACKAGE__->has_many(
  "actions",
  "AdministratorDB::Schema::Result::Action",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 actions_triggered

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ActionTriggered>

=cut

__PACKAGE__->has_many(
  "actions_triggered",
  "AdministratorDB::Schema::Result::ActionTriggered",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 aggregate_combinations

Type: has_many

Related object: L<AdministratorDB::Schema::Result::AggregateCombination>

=cut

__PACKAGE__->has_many(
  "aggregate_combinations",
  "AdministratorDB::Schema::Result::AggregateCombination",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 aggregate_conditions

Type: has_many

Related object: L<AdministratorDB::Schema::Result::AggregateCondition>

=cut

__PACKAGE__->has_many(
  "aggregate_conditions",
  "AdministratorDB::Schema::Result::AggregateCondition",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 aggregate_rules

Type: has_many

Related object: L<AdministratorDB::Schema::Result::AggregateRule>

=cut

__PACKAGE__->has_many(
  "aggregate_rules",
  "AdministratorDB::Schema::Result::AggregateRule",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 clustermetrics

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Clustermetric>

=cut

__PACKAGE__->has_many(
  "clustermetrics",
  "AdministratorDB::Schema::Result::Clustermetric",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entities

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->has_many(
  "entities",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicators

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Indicator>

=cut

__PACKAGE__->has_many(
  "indicators",
  "AdministratorDB::Schema::Result::Indicator",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_combinations

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NodemetricCombination>

=cut

__PACKAGE__->has_many(
  "nodemetric_combinations",
  "AdministratorDB::Schema::Result::NodemetricCombination",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_conditions

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NodemetricCondition>

=cut

__PACKAGE__->has_many(
  "nodemetric_conditions",
  "AdministratorDB::Schema::Result::NodemetricCondition",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_rules

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NodemetricRule>

=cut

__PACKAGE__->has_many(
  "nodemetric_rules",
  "AdministratorDB::Schema::Result::NodemetricRule",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 scom_indicators

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ScomIndicator>

=cut

__PACKAGE__->has_many(
  "scom_indicators",
  "AdministratorDB::Schema::Result::ScomIndicator",
  { "foreign.class_type_id" => "self.class_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-05-10 14:35:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FK7zU0KfSzT6Q6nrBwjKYA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
