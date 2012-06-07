use utf8;
package AdministratorDB::Schema::Result::AggregateRule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::AggregateRule

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<aggregate_rule>

=cut

__PACKAGE__->table("aggregate_rule");

=head1 ACCESSORS

=head2 aggregate_rule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 aggregate_rule_label

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 aggregate_rule_service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 aggregate_rule_formula

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 aggregate_rule_last_eval

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 aggregate_rule_timestamp

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 aggregate_rule_state

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 aggregate_rule_description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "aggregate_rule_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "aggregate_rule_label",
  { data_type => "char", is_nullable => 1, size => 255 },
  "aggregate_rule_service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "aggregate_rule_formula",
  { data_type => "char", is_nullable => 0, size => 32 },
  "aggregate_rule_last_eval",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "aggregate_rule_timestamp",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "aggregate_rule_state",
  { data_type => "char", is_nullable => 0, size => 32 },
  "aggregate_rule_description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</aggregate_rule_id>

=back

=cut

__PACKAGE__->set_primary_key("aggregate_rule_id");

=head1 RELATIONS

=head2 aggregate_rule_service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "aggregate_rule_service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "aggregate_rule_service_provider_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-07 19:20:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:twLkqf5am5kbC8qV9TWrxQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
