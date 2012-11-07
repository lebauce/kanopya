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
  is_foreign_key: 1
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

=head2 comparator

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 aggregate_condition_formula_string

  data_type: 'text'
  is_nullable: 0

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
    is_foreign_key => 1,
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
  "comparator",
  { data_type => "char", is_nullable => 0, size => 32 },
  "aggregate_condition_formula_string",
  { data_type => "text", is_nullable => 0 },
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

=head2 aggregate_condition

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "aggregate_condition",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "aggregate_condition_id" },
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

=head2 left_combination

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Combination>

=cut

__PACKAGE__->belongs_to(
  "left_combination",
  "AdministratorDB::Schema::Result::Combination",
  { combination_id => "left_combination_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 right_combination

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Combination>

=cut

__PACKAGE__->belongs_to(
  "right_combination",
  "AdministratorDB::Schema::Result::Combination",
  { combination_id => "right_combination_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-10-31 16:06:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+bAOoyzxl26S8wnuEoTkRg

 __PACKAGE__->belongs_to(
   "parent",
     "AdministratorDB::Schema::Result::Entity",
         { "foreign.entity_id" => "self.aggregate_condition_id" },
             { cascade_copy => 0, cascade_delete => 1 }
 );


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
