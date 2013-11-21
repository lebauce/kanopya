use utf8;
package Kanopya::Schema::Result::Workflow;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Workflow

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

=head1 TABLE: C<workflow>

=cut

__PACKAGE__->table("workflow");

=head1 ACCESSORS

=head2 workflow_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 workflow_name

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 state

  data_type: 'char'
  default_value: 'pending'
  is_nullable: 0
  size: 32

=head2 related_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "workflow_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "workflow_name",
  { data_type => "char", is_nullable => 1, size => 64 },
  "state",
  {
    data_type => "char",
    default_value => "pending",
    is_nullable => 0,
    size => 32,
  },
  "related_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</workflow_id>

=back

=cut

__PACKAGE__->set_primary_key("workflow_id");

=head1 RELATIONS

=head2 aggregate_rules

Type: has_many

Related object: L<Kanopya::Schema::Result::AggregateRule>

=cut

__PACKAGE__->has_many(
  "aggregate_rules",
  "Kanopya::Schema::Result::AggregateRule",
  { "foreign.workflow_id" => "self.workflow_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 old_operations

Type: has_many

Related object: L<Kanopya::Schema::Result::OldOperation>

=cut

__PACKAGE__->has_many(
  "old_operations",
  "Kanopya::Schema::Result::OldOperation",
  { "foreign.workflow_id" => "self.workflow_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 operations

Type: has_many

Related object: L<Kanopya::Schema::Result::Operation>

=cut

__PACKAGE__->has_many(
  "operations",
  "Kanopya::Schema::Result::Operation",
  { "foreign.workflow_id" => "self.workflow_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 related

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "related",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "related_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 workflow

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "workflow",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "workflow_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 workflow_noderules

Type: has_many

Related object: L<Kanopya::Schema::Result::WorkflowNoderule>

=cut

__PACKAGE__->has_many(
  "workflow_noderules",
  "Kanopya::Schema::Result::WorkflowNoderule",
  { "foreign.workflow_id" => "self.workflow_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jSva8B1TjezBLhaOq/h9/Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
