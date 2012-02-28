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

=head2 aggregate_rule_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 aggregate_rule_formula

  data_type: 'text'
  is_nullable: 0

=head2 aggregate_rule_last_eval

  data_type: 'integer'
  is_nullable: 1

=head2 aggregate_rule_timestamp

  data_type: 'integer'
  is_nullable: 1

=head2 aggregate_rule_state

  data_type: 'text'
  is_nullable: 0

=head2 aggregate_rule_action_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "aggregate_rule_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "aggregate_rule_formula",
  { data_type => "text", is_nullable => 0 },
  "aggregate_rule_last_eval",
  { data_type => "integer", is_nullable => 1 },
  "aggregate_rule_timestamp",
  { data_type => "integer", is_nullable => 1 },
  "aggregate_rule_state",
  { data_type => "text", is_nullable => 0 },
  "aggregate_rule_action_id",
  { data_type => "integer", is_nullable => 0 },
      "class_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("aggregate_rule_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-02-15 13:58:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:doTpkeVMPAOe1v9NT7zJPA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
