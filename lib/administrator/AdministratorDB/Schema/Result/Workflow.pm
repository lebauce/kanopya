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
);
__PACKAGE__->set_primary_key("workflow_id");

=head1 RELATIONS

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

=head2 workflow_parameters

Type: has_many

Related object: L<AdministratorDB::Schema::Result::WorkflowParameter>

=cut

__PACKAGE__->has_many(
  "workflow_parameters",
  "AdministratorDB::Schema::Result::WorkflowParameter",
  { "foreign.workflow_id" => "self.workflow_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-05-22 15:15:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CylQKFpQpw2x7AnCXl5DWA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
