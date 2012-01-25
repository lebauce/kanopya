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
  datetime_undef_if_invalid: 1
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
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
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
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-01-25 14:19:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Hcp5tV6Yg7oYSMITG5+w5A


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
  "entitylink",
  "AdministratorDB::Schema::Result::MessageEntity",
    { "foreign.message_id" => "self.message_id" },
    { cascade_copy => 0, cascade_delete => 0 });
1;
