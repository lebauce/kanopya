use utf8;
package AdministratorDB::Schema::Result::WorkflowNoderule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::WorkflowNoderule

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

=head1 TABLE: C<workflow_noderule>

=cut

__PACKAGE__->table("workflow_noderule");

=head1 ACCESSORS

=head2 workflow_noderule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 node_id

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

=head2 workflow_untriggerable_timestamp

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "workflow_noderule_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "node_id",
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
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</workflow_noderule_id>

=back

=cut

__PACKAGE__->set_primary_key("workflow_noderule_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<node_id>

=over 4

=item * L</node_id>

=item * L</nodemetric_rule_id>

=item * L</workflow_id>

=back

=cut

__PACKAGE__->add_unique_constraint("node_id", ["node_id", "nodemetric_rule_id", "workflow_id"]);

=head1 RELATIONS

=head2 node

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Node>

=cut

__PACKAGE__->belongs_to(
  "node",
  "AdministratorDB::Schema::Result::Node",
  { node_id => "node_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-02-04 17:48:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:D2r69/FBFBsKSVEEkZ38Mw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
