package AdministratorDB::Schema::Result::WorkflowDef;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::WorkflowDef

=cut

__PACKAGE__->table("workflow_def");

=head1 ACCESSORS

=head2 workflow_def_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 workflow_def_name

  data_type: 'char'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "workflow_def_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "workflow_def_name",
  { data_type => "char", is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("workflow_def_id");
__PACKAGE__->add_unique_constraint("workflow_def_name", ["workflow_def_name"]);

=head1 RELATIONS

=head2 workflow_instances

Type: has_many

Related object: L<AdministratorDB::Schema::Result::WorkflowInstance>

=cut

__PACKAGE__->has_many(
  "workflow_instances",
  "AdministratorDB::Schema::Result::WorkflowInstance",
  { "foreign.workflow_def_id" => "self.workflow_def_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workflow_steps

Type: has_many

Related object: L<AdministratorDB::Schema::Result::WorkflowStep>

=cut

__PACKAGE__->has_many(
  "workflow_steps",
  "AdministratorDB::Schema::Result::WorkflowStep",
  { "foreign.workflow_def_id" => "self.workflow_def_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-05-30 14:27:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zmLJUFs9yUl/TrdMHAKFiw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
