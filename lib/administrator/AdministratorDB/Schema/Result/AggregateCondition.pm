use utf8;
package AdministratorDB::Schema::Result::AggregateCondition;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::AggregateCondition

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<aggregate_condition>

=cut

__PACKAGE__->table("aggregate_condition");

=head1 ACCESSORS

=head2 aggregate_condition_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 aggregate_condition_label

  data_type: 'char'
  is_nullable: 1
  size: 255

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

=cut

__PACKAGE__->add_columns(
  "aggregate_condition_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "aggregate_condition_label",
  { data_type => "char", is_nullable => 1, size => 255 },
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
);

=head1 PRIMARY KEY

=over 4

=item * L</aggregate_condition_id>

=back

=cut

__PACKAGE__->set_primary_key("aggregate_condition_id");

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-07 16:11:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NIGLIz6oY/x5k4YVtpBesQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
