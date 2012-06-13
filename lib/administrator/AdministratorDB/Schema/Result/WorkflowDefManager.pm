package AdministratorDB::Schema::Result::WorkflowDefManager;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::WorkflowDefManager

=cut

__PACKAGE__->table("workflow_def_manager");

=head1 ACCESSORS

=head2 workflow_def_manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 manager_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 workflow_def_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "workflow_def_manager_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "manager_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "workflow_def_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key("workflow_def_manager_id");
__PACKAGE__->add_unique_constraint("manager_id", ["manager_id", "workflow_def_id"]);

=head1 RELATIONS

=head2 workflow_def

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::WorkflowDef>

=cut

__PACKAGE__->belongs_to(
  "workflow_def",
  "AdministratorDB::Schema::Result::WorkflowDef",
  { workflow_def_id => "workflow_def_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-06-13 17:32:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tltltO81/vmWTHRLHH8l2g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
