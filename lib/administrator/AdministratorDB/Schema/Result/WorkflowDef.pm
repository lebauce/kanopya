use utf8;
package AdministratorDB::Schema::Result::WorkflowDef;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::WorkflowDef

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<workflow_def>

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

=head2 param_preset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

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
  "param_preset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</workflow_def_id>

=back

=cut

__PACKAGE__->set_primary_key("workflow_def_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<workflow_def_name>

=over 4

=item * L</workflow_def_name>

=back

=cut

__PACKAGE__->add_unique_constraint("workflow_def_name", ["workflow_def_name"]);

=head1 RELATIONS

=head2 param_preset

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ParamPreset>

=cut

__PACKAGE__->belongs_to(
  "param_preset",
  "AdministratorDB::Schema::Result::ParamPreset",
  { param_preset_id => "param_preset_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 workflow_def_managers

Type: has_many

Related object: L<AdministratorDB::Schema::Result::WorkflowDefManager>

=cut

__PACKAGE__->has_many(
  "workflow_def_managers",
  "AdministratorDB::Schema::Result::WorkflowDefManager",
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


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-06-08 14:15:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:db6bctsP+fkUrZEsXEBG2A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
