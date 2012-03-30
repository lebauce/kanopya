package AdministratorDB::Schema::Result::ActionParameter;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ActionParameter

=cut

__PACKAGE__->table("action_parameter");

=head1 ACCESSORS

=head2 action_parameter_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 action_parameter_name

  data_type: 'char'
  is_nullable: 0
  size: 64

=head2 action_parameter_value

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 action_parameter_action_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "action_parameter_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "action_parameter_name",
  { data_type => "char", is_nullable => 0, size => 64 },
  "action_parameter_value",
  { data_type => "char", is_nullable => 1, size => 255 },
  "action_parameter_action_id",
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
__PACKAGE__->set_primary_key("action_parameter_id");

=head1 RELATIONS

=head2 action_parameter_action

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Action>

=cut

__PACKAGE__->belongs_to(
  "action_parameter_action",
  "AdministratorDB::Schema::Result::Action",
  { action_id => "action_parameter_action_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-28 12:37:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jHYv1X6myFOs6QnTl7qS6A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
