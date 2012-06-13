package AdministratorDB::Schema::Result::Operation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Operation

=cut

__PACKAGE__->table("operation");

=head1 ACCESSORS

=head2 operation_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 type

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=head2 workflow_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 state

  data_type: 'char'
  default_value: 'pending'
  is_nullable: 0
  size: 32

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

=head2 hoped_execution_time

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 execution_rank

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "operation_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "type",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 64 },
  "workflow_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "state",
  {
    data_type => "char",
    default_value => "pending",
    is_nullable => 0,
    size => 32,
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
  "hoped_execution_time",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "execution_rank",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("operation_id");
__PACKAGE__->add_unique_constraint("execution_rank", ["execution_rank", "workflow_id"]);

=head1 RELATIONS

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

=head2 type

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Operationtype>

=cut

__PACKAGE__->belongs_to(
  "type",
  "AdministratorDB::Schema::Result::Operationtype",
  { operationtype_name => "type" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 operation_parameters

Type: has_many

Related object: L<AdministratorDB::Schema::Result::OperationParameter>

=cut

__PACKAGE__->has_many(
  "operation_parameters",
  "AdministratorDB::Schema::Result::OperationParameter",
  { "foreign.operation_id" => "self.operation_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-06-12 10:46:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cd13OMAP+pDjvbVi7NIFOw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
