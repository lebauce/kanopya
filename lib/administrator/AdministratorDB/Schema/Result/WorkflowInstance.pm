package AdministratorDB::Schema::Result::WorkflowInstance;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::WorkflowInstance

=cut

__PACKAGE__->table("workflow_instance");

=head1 ACCESSORS

=head2 workflow_instance_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 aggregate_rule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 nodemetric_rule_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 workflow_def_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 class_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "workflow_instance_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "aggregate_rule_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "nodemetric_rule_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "workflow_def_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "class_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("workflow_instance_id");

=head1 RELATIONS

=head2 class_type

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ClassType>

=cut

__PACKAGE__->belongs_to(
  "class_type",
  "AdministratorDB::Schema::Result::ClassType",
  { class_type_id => "class_type_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 aggregate_rule

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::AggregateRule>

=cut

__PACKAGE__->belongs_to(
  "aggregate_rule",
  "AdministratorDB::Schema::Result::AggregateRule",
  { aggregate_rule_id => "aggregate_rule_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 nodemetric_rule

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::NodemetricRule>

=cut

__PACKAGE__->belongs_to(
  "nodemetric_rule",
  "AdministratorDB::Schema::Result::NodemetricRule",
  { nodemetric_rule_id => "nodemetric_rule_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 workflow_def

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::WorkflowDef>

=cut

__PACKAGE__->belongs_to(
  "workflow_def",
  "AdministratorDB::Schema::Result::WorkflowDef",
  { workflow_def_id => "workflow_def_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 workflow_instance_params

Type: has_many

Related object: L<AdministratorDB::Schema::Result::WorkflowInstanceParam>

=cut

__PACKAGE__->has_many(
  "workflow_instance_params",
  "AdministratorDB::Schema::Result::WorkflowInstanceParam",
  { "foreign.workflow_instance_id" => "self.workflow_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow_instance_parameters

Type: has_many

Related object: L<AdministratorDB::Schema::Result::WorkflowInstanceParameter>

=cut

__PACKAGE__->has_many(
  "workflow_instance_parameters",
  "AdministratorDB::Schema::Result::WorkflowInstanceParameter",
  { "foreign.workflow_instance_id" => "self.workflow_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-05-30 14:27:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Hm1T0yd6/AKJQFE4Uy5hmg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
