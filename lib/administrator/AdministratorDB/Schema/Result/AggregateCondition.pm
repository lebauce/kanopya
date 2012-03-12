package AdministratorDB::Schema::Result::AggregateCondition;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::AggregateCondition

=cut

__PACKAGE__->table("aggregate_condition");

=head1 ACCESSORS

=head2 aggregate_condition_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 aggregate_condition_service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 aggregate_combination_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 comparator

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 threshold

  data_type: 'double precision'
  is_nullable: 0

=head2 state

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 time_limit

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 last_eval

  data_type: 'tinyint'
  is_nullable: 1

=head2 class_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "aggregate_condition_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "aggregate_condition_service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "aggregate_combination_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "comparator",
  { data_type => "char", is_nullable => 0, size => 32 },
  "threshold",
  { data_type => "double precision", is_nullable => 0 },
  "state",
  { data_type => "char", is_nullable => 0, size => 32 },
  "time_limit",
  { data_type => "char", is_nullable => 1, size => 32 },
  "last_eval",
  { data_type => "tinyint", is_nullable => 1 },
  "class_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("aggregate_condition_id");

=head1 RELATIONS

=head2 aggregate_condition_service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "aggregate_condition_service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  {
    service_provider_id => "aggregate_condition_service_provider_id",
  },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
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

=head2 aggregate_combination

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::AggregateCombination>

=cut

__PACKAGE__->belongs_to(
  "aggregate_combination",
  "AdministratorDB::Schema::Result::AggregateCombination",
  { aggregate_combination_id => "aggregate_combination_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-08 10:27:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:km5gKiW4cOvUddLpUdoMMQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
