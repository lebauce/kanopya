use utf8;
package Kanopya::Schema::Result::WorkflowDefManager;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::WorkflowDefManager

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

=head1 TABLE: C<workflow_def_manager>

=cut

__PACKAGE__->table("workflow_def_manager");

=head1 ACCESSORS

=head2 manager_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 workflow_def_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "manager_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "workflow_def_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</manager_id>

=item * L</workflow_def_id>

=back

=cut

__PACKAGE__->set_primary_key("manager_id", "workflow_def_id");

=head1 RELATIONS

=head2 manager

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "manager",
  "Kanopya::Schema::Result::Component",
  { component_id => "manager_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 workflow_def

Type: belongs_to

Related object: L<Kanopya::Schema::Result::WorkflowDef>

=cut

__PACKAGE__->belongs_to(
  "workflow_def",
  "Kanopya::Schema::Result::WorkflowDef",
  { workflow_def_id => "workflow_def_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-26 15:43:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lNzVNkbdDiLhRqQx+dInVQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
