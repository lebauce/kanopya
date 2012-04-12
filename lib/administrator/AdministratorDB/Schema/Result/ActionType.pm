package AdministratorDB::Schema::Result::ActionType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ActionType

=cut

__PACKAGE__->table("action_type");

=head1 ACCESSORS

=head2 action_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 action_type_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 class_type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "action_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "action_type_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "class_type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("action_type_id");

=head1 RELATIONS

=head2 actions

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Action>

=cut

__PACKAGE__->has_many(
  "actions",
  "AdministratorDB::Schema::Result::Action",
  { "foreign.action_action_type_id" => "self.action_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 class_type

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ClassType>

=cut

__PACKAGE__->belongs_to(
  "class_type",
  "AdministratorDB::Schema::Result::ClassType",
  { class_type_id => "class_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 action_type_parameters

Type: has_many

Related object: L<AdministratorDB::Schema::Result::ActionTypeParameter>

=cut

__PACKAGE__->has_many(
  "action_type_parameters",
  "AdministratorDB::Schema::Result::ActionTypeParameter",
  {
    "foreign.action_type_parameter_action_type_id" => "self.action_type_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-04-04 10:39:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lsm55jfmwfaode+8lVuI3Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
