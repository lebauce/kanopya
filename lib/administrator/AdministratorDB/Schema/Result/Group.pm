package AdministratorDB::Schema::Result::Group;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Group

=cut

__PACKAGE__->table("groups");

=head1 ACCESSORS

=head2 groups_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 groups_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 groups_type

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 groups_desc

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 groups_system

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "groups_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "groups_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "groups_type",
  { data_type => "char", is_nullable => 0, size => 32 },
  "groups_desc",
  { data_type => "char", is_nullable => 1, size => 255 },
  "groups_system",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("groups_id");
__PACKAGE__->add_unique_constraint("groups_name", ["groups_name"]);

=head1 RELATIONS

=head2 groups_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::GroupsEntity>

=cut

__PACKAGE__->might_have(
  "groups_entity",
  "AdministratorDB::Schema::Result::GroupsEntity",
  { "foreign.groups_id" => "self.groups_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ingroups

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Ingroup>

=cut

__PACKAGE__->has_many(
  "ingroups",
  "AdministratorDB::Schema::Result::Ingroup",
  { "foreign.groups_id" => "self.groups_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Yb35OV66nQN3BJtOwDKCAw


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::GroupsEntity",
    { "foreign.groups_id" => "self.groups_id" },
    { cascade_copy => 0, cascade_delete => 0 });
1;
