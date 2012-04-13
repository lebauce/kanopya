package AdministratorDB::Schema::Result::ServiceProvider;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ServiceProvider

=cut

__PACKAGE__->table("service_provider");

=head1 ACCESSORS

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("service_provider_id");

=head1 RELATIONS

=head2 actions

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Action>

=cut

__PACKAGE__->has_many(
  "actions",
  "AdministratorDB::Schema::Result::Action",
  {
    "foreign.action_service_provider_id" => "self.service_provider_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


=head2 aggregate_combinations

Type: has_many

Related object: L<AdministratorDB::Schema::Result::AggregateCombination>

=cut

__PACKAGE__->has_many(
  "aggregate_combinations",
  "AdministratorDB::Schema::Result::AggregateCombination",
  {
    "foreign.aggregate_combination_service_provider_id" => "self.service_provider_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 aggregate_conditions

Type: has_many

Related object: L<AdministratorDB::Schema::Result::AggregateCondition>

=cut

__PACKAGE__->has_many(
  "aggregate_conditions",
  "AdministratorDB::Schema::Result::AggregateCondition",
  {
    "foreign.aggregate_condition_service_provider_id" => "self.service_provider_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 aggregate_rules

Type: has_many

Related object: L<AdministratorDB::Schema::Result::AggregateRule>

=cut

__PACKAGE__->has_many(
  "aggregate_rules",
  "AdministratorDB::Schema::Result::AggregateRule",
  {
    "foreign.aggregate_rule_service_provider_id" => "self.service_provider_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 clustermetrics

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Clustermetric>

=cut

__PACKAGE__->has_many(
  "clustermetrics",
  "AdministratorDB::Schema::Result::Clustermetric",
  {
    "foreign.clustermetric_service_provider_id" => "self.service_provider_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 inside

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Inside>

=cut

__PACKAGE__->might_have(
  "inside",
  "AdministratorDB::Schema::Result::Inside",
  { "foreign.inside_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 interfaces

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Interface>

=cut

__PACKAGE__->has_many(
  "interfaces",
  "AdministratorDB::Schema::Result::Interface",
  { "foreign.service_provider_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodemetric_rules

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NodemetricRule>

=cut

__PACKAGE__->has_many(
  "nodemetric_rules",
  "AdministratorDB::Schema::Result::NodemetricRule",
  {
    "foreign.nodemetric_rule_service_provider_id" => "self.service_provider_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "nodemetric_conditions",
  "AdministratorDB::Schema::Result::NodemetricCondition",
  {
    "foreign.nodemetric_condition_service_provider_id" => "self.service_provider_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "nodemetric_combinations",
  "AdministratorDB::Schema::Result::NodemetricCombination",
  {
    "foreign.nodemetric_combination_service_provider_id" => "self.service_provider_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 outside

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Outside>

=cut

__PACKAGE__->might_have(
  "outside",
  "AdministratorDB::Schema::Result::Outside",
  { "foreign.outside_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "service_provider_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-04-05 20:08:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jmeQMTUC0LG2/ymZYpgUtw

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.entity_id" => "self.service_provider_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
