use utf8;
package AdministratorDB::Schema::Result::WorkflowNoderule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::WorkflowNoderule

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<workflow_noderule>

=cut

__PACKAGE__->table("workflow_noderule");

=head1 ACCESSORS

=head2 workflow_noderule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 externalnode_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 nodemetric_rule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 workflow_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "workflow_noderule_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "externalnode_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "nodemetric_rule_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "workflow_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "workflow_untriggerable_timestamp",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 0,
    is_nullable => 1,
  },

);

=head1 PRIMARY KEY

=over 4

=item * L</workflow_noderule_id>

=back

=cut

__PACKAGE__->set_primary_key("workflow_noderule_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<externalnode_id>

=over 4

=item * L</externalnode_id>

=item * L</nodemetric_rule_id>

=item * L</workflow_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "externalnode_id",
  ["externalnode_id", "nodemetric_rule_id", "workflow_id"],
);

=head1 RELATIONS

=head2 externalnode

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Externalnode>

=cut

__PACKAGE__->belongs_to(
  "externalnode",
  "AdministratorDB::Schema::Result::Externalnode",
  { externalnode_id => "externalnode_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 nodemetric_rule

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::NodemetricRule>

=cut

__PACKAGE__->belongs_to(
  "nodemetric_rule",
  "AdministratorDB::Schema::Result::NodemetricRule",
  { nodemetric_rule_id => "nodemetric_rule_id" },
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
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-07-03 15:20:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:h3vDXi9ibeKtCJHwiMrGtg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
