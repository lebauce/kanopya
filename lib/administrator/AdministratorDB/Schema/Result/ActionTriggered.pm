package AdministratorDB::Schema::Result::ActionTriggered;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::ActionTriggered

=cut

__PACKAGE__->table("action_triggered");

=head1 ACCESSORS

=head2 action_triggered_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 action_triggered_hostname

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 action_triggered_timestamp

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 action_triggered_action_id

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
  "action_triggered_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "action_triggered_hostname",
  { data_type => "char", is_nullable => 1, size => 255 },
  "action_triggered_timestamp",
  { data_type => "char", is_nullable => 0, size => 255 },
  "action_triggered_action_id",
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
__PACKAGE__->set_primary_key("action_triggered_id");


=head1 RELATIONS

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

=head2 action_triggered_action

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Action>

=cut

__PACKAGE__->belongs_to(
  "action_triggered_action",
  "AdministratorDB::Schema::Result::Action",
  { action_id => "action_triggered_action_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-28 12:37:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bhFWXOBTadUWZ224PtLqmQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
