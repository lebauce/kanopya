package AdministratorDB::Schema::Result::OldOperationParameter;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::OperationParameter

=cut

__PACKAGE__->table("old_operation_parameter");

=head1 ACCESSORS

=head2 old_operation_param_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 value

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 old_operation_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "old_operation_param_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "value",
  { data_type => "char", is_nullable => 0, size => 255 },
  "old_operation_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("old_operation_param_id");

=head1 RELATIONS

=head2 operation

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Operation>

=cut

__PACKAGE__->belongs_to(
  "operation",
  "AdministratorDB::Schema::Result::OldOperation",
  { old_operation_id => "old_operation_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:O5vFNRBuDa4B79/XXV2Beg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
