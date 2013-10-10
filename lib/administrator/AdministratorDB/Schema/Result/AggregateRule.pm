use utf8;
package AdministratorDB::Schema::Result::AggregateRule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::AggregateRule

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

=head1 TABLE: C<aggregate_rule>

=cut

__PACKAGE__->table("aggregate_rule");

=head1 ACCESSORS

=head2 aggregate_rule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 aggregate_rule_last_eval

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 workflow_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 workflow_untriggerable_timestamp

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "aggregate_rule_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "aggregate_rule_last_eval",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "workflow_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "workflow_untriggerable_timestamp",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</aggregate_rule_id>

=back

=cut

__PACKAGE__->set_primary_key("aggregate_rule_id");

=head1 RELATIONS

=head2 aggregate_rule

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Rule>

=cut

__PACKAGE__->belongs_to(
  "aggregate_rule",
  "AdministratorDB::Schema::Result::Rule",
  { rule_id => "aggregate_rule_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 workflow

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Workflow>

=cut

__PACKAGE__->belongs_to(
  "workflow",
  "AdministratorDB::Schema::Result::Workflow",
  { workflow_id => "workflow_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);



# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-10-31 16:06:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:610K8tyOsweKbgyesSqb7A

 __PACKAGE__->belongs_to(
   "parent",
     "AdministratorDB::Schema::Result::Rule",
         { "foreign.rule_id" => "self.aggregate_rule_id" },
             { cascade_copy => 0, cascade_delete => 1 }
 );


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
