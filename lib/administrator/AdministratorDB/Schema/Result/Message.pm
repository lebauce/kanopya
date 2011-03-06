package AdministratorDB::Schema::Result::Message;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Message

=cut

__PACKAGE__->table("message");

=head1 ACCESSORS

=head2 message_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 message_from

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 message_creationdate

  data_type: 'date'
  is_nullable: 0

=head2 message_creationtime

  data_type: 'time'
  is_nullable: 0

=head2 message_level

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 message_content

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "message_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "user_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "message_from",
  { data_type => "char", is_nullable => 0, size => 32 },
  "message_creationdate",
  { data_type => "date", is_nullable => 0 },
  "message_creationtime",
  { data_type => "time", is_nullable => 0 },
  "message_level",
  { data_type => "char", is_nullable => 0, size => 32 },
  "message_content",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("message_id");

=head1 RELATIONS

=head2 user

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "AdministratorDB::Schema::Result::User",
  { user_id => "user_id" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 message_entity

Type: might_have

Related object: L<AdministratorDB::Schema::Result::MessageEntity>

=cut

__PACKAGE__->might_have(
  "message_entity",
  "AdministratorDB::Schema::Result::MessageEntity",
  { "foreign.message_id" => "self.message_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-18 11:02:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Yq27xSQG+A5q6ioXicxBvA


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::MessageEntity",
    { "foreign.message_id" => "self.message_id" },
    { cascade_copy => 0, cascade_delete => 0 });
1;
