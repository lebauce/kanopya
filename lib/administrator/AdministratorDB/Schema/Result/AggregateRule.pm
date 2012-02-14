package AdministratorDB::Schema::Result::AggregateRule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::AggregateRule

=cut

__PACKAGE__->table("aggregate_rule");

=head1 ACCESSORS

=head2 rule_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 aggregate_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 comparator

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 threshold

  data_type: 'double'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 state

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 time_limit

  data_type: 'char'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "rule_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "aggregate_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "comparator",
  { data_type => "char", is_nullable => 0, size => 32 },
  "threshold",
  { data_type => "double", extra => { unsigned => 1 }, is_nullable => 0 },
  "state",
  { data_type => "char", is_nullable => 0, size => 32 },
  "time_limit",
  { data_type => "char", is_nullable => 1, size => 32 },
  "last_eval",
  { data_type => "boolean", is_nullable => 1 },
  
);
__PACKAGE__->set_primary_key("rule_id");

=head1 RELATIONS

=head2 aggregate

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Aggregate>

=cut

__PACKAGE__->belongs_to(
  "aggregate",
  "AdministratorDB::Schema::Result::Aggregate",
  { aggregate_id => "aggregate_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-02-06 17:38:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YTPhRcESJ6YwGoXPwoGyXw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
