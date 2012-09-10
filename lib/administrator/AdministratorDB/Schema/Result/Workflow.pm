package AdministratorDB::Schema::Result::Workflow;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Workflow

=cut

__PACKAGE__->table("workflow");

=head1 ACCESSORS

=head2 workflow_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 workflow_name

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 state

  data_type: 'char'
  default_value: 'running'
  is_nullable: 0
  size: 32

=head2 entity_id

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
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "workflow_name",
  { data_type => "char", is_nullable => 1, size => 64 },
  "state",
  {
    data_type => "char",
    default_value => "running",
    is_nullable => 0,
    size => 32,
  },
  "entity_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("workflow_id");

=head1 RELATIONS

=head2 aggregate_rules

Type: has_many

Related object: L<AdministratorDB::Schema::Result::AggregateRule>

=cut

__PACKAGE__->has_many(
  "aggregate_rules",
  "AdministratorDB::Schema::Result::AggregateRule",
  { "foreign.workflow_id" => "self.workflow_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entity_locks

Type: has_many

Related object: L<AdministratorDB::Schema::Result::EntityLock>

=cut

__PACKAGE__->has_many(
  "entity_locks",
  "AdministratorDB::Schema::Result::EntityLock",
  { "foreign.workflow_id" => "self.workflow_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 old_operations

Type: has_many

Related object: L<AdministratorDB::Schema::Result::OldOperation>

=cut

__PACKAGE__->has_many(
  "old_operations",
  "AdministratorDB::Schema::Result::OldOperation",
  { "foreign.workflow_id" => "self.workflow_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 operations

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Operation>

=cut

__PACKAGE__->has_many(
  "operations",
  "AdministratorDB::Schema::Result::Operation",
  { "foreign.workflow_id" => "self.workflow_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 entity

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "entity",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "entity_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 workflow_noderules

Type: has_many

Related object: L<AdministratorDB::Schema::Result::WorkflowNoderule>

=cut

__PACKAGE__->has_many(
  "workflow_noderules",
  "AdministratorDB::Schema::Result::WorkflowNoderule",
  { "foreign.workflow_id" => "self.workflow_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-09-10 17:17:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:59pmYIPPFCJm095fPtAlvw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
