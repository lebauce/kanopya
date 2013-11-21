use utf8;
package Kanopya::Schema::Result::Message;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Message

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

=head1 TABLE: C<message>

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

=head1 PRIMARY KEY

=over 4

=item * L</message_id>

=back

=cut

__PACKAGE__->set_primary_key("message_id");

=head1 RELATIONS

=head2 user

Type: belongs_to

Related object: L<Kanopya::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Kanopya::Schema::Result::User",
  { user_id => "user_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Om6JD1L6hwxKqzfx41iEqg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
