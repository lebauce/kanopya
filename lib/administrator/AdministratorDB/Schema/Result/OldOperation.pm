use utf8;
package AdministratorDB::Schema::Result::OldOperation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::OldOperation

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

=head1 TABLE: C<old_operation>

=cut

__PACKAGE__->table("old_operation");

=head1 ACCESSORS

=head2 old_operation_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 operation_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 operationtype_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 workflow_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 priority

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 creation_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 creation_time

  data_type: 'time'
  is_nullable: 0

=head2 execution_date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 execution_time

  data_type: 'time'
  is_nullable: 0

=head2 execution_status

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 param_preset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "old_operation_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "operation_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "operationtype_id",
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
  "user_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "priority",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "creation_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "creation_time",
  { data_type => "time", is_nullable => 0 },
  "execution_date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "execution_time",
  { data_type => "time", is_nullable => 0 },
  "execution_status",
  { data_type => "char", is_nullable => 0, size => 32 },
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

=item * L</old_operation_id>

=back

=cut

__PACKAGE__->set_primary_key("old_operation_id");

=head1 RELATIONS

=head2 operationtype

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Operationtype>

=cut

__PACKAGE__->belongs_to(
  "operationtype",
  "AdministratorDB::Schema::Result::Operationtype",
  { operationtype_id => "operationtype_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

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

=head2 user

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "AdministratorDB::Schema::Result::User",
  { user_id => "user_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2013-04-16 11:59:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QWqAihDbWY89JLOGHKCKmA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
