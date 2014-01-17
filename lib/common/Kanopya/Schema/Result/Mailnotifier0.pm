use utf8;
package Kanopya::Schema::Result::Mailnotifier0;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Mailnotifier0

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

=head1 TABLE: C<mailnotifier0>

=cut

__PACKAGE__->table("mailnotifier0");

=head1 ACCESSORS

=head2 mailnotifier0_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 smtp_server

  data_type: 'char'
  default_value: 'localhost'
  is_nullable: 1
  size: 255

=head2 smtp_login

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 smtp_passwd

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 use_ssl

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "mailnotifier0_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "smtp_server",
  {
    data_type => "char",
    default_value => "localhost",
    is_nullable => 1,
    size => 255,
  },
  "smtp_login",
  { data_type => "char", is_nullable => 1, size => 32 },
  "smtp_passwd",
  { data_type => "char", is_nullable => 1, size => 32 },
  "use_ssl",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</mailnotifier0_id>

=back

=cut

__PACKAGE__->set_primary_key("mailnotifier0_id");

=head1 RELATIONS

=head2 mailnotifier0

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "mailnotifier0",
  "Kanopya::Schema::Result::Component",
  { component_id => "mailnotifier0_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KBEFQkaQaqsyBkoGfu3PUw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
