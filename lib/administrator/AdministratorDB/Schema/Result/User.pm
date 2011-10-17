package AdministratorDB::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::User

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 user_system

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 user_login

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 user_password

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 user_firstname

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 user_lastname

  data_type: 'char'
  is_nullable: 1
  size: 64

=head2 user_email

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 user_creationdate

  data_type: 'date'
  is_nullable: 1

=head2 user_lastaccess

  data_type: 'datetime'
  is_nullable: 1

=head2 user_desc

  data_type: 'char'
  default_value: 'Note concerning this user'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "user_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "user_system",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "user_login",
  { data_type => "char", is_nullable => 0, size => 32 },
  "user_password",
  { data_type => "char", is_nullable => 0, size => 32 },
  "user_firstname",
  { data_type => "char", is_nullable => 1, size => 64 },
  "user_lastname",
  { data_type => "char", is_nullable => 1, size => 64 },
  "user_email",
  { data_type => "char", is_nullable => 1, size => 255 },
  "user_creationdate",
  { data_type => "date", is_nullable => 1 },
  "user_lastaccess",
  { data_type => "datetime", is_nullable => 1 },
  "user_desc",
  {
    data_type => "char",
    default_value => "Note concerning this user",
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("user_id");
__PACKAGE__->add_unique_constraint("user_login", ["user_login"]);

=head1 RELATIONS

=head2 messages

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Message>

=cut

__PACKAGE__->has_many(
  "messages",
  "AdministratorDB::Schema::Result::Message",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 old_operations

Type: has_many

Related object: L<AdministratorDB::Schema::Result::OldOperation>

=cut

__PACKAGE__->has_many(
  "old_operations",
  "AdministratorDB::Schema::Result::OldOperation",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 operations

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Operation>

=cut

__PACKAGE__->has_many(
  "operations",
  "AdministratorDB::Schema::Result::Operation",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::UserEntity>

=cut

__PACKAGE__->might_have(
  "user_entity",
  "AdministratorDB::Schema::Result::UserEntity",
  { "foreign.user_id" => "self.user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:glCgFztj/vT87xFcdIyTpg


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::UserEntity",
    { "foreign.user_id" => "self.user_id" },
    { cascade_copy => 0, cascade_delete => 0 });

1;
