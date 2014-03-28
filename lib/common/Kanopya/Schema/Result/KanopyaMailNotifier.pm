use utf8;
package Kanopya::Schema::Result::KanopyaMailNotifier;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::KanopyaMailNotifier

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

=head1 TABLE: C<kanopya_mail_notifier>

=cut

__PACKAGE__->table("kanopya_mail_notifier");

=head1 ACCESSORS

=head2 kanopya_mail_notifier_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 control_queue

  data_type: 'char'
  is_nullable: 1
  size: 255

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
  "kanopya_mail_notifier_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "control_queue",
  { data_type => "char", is_nullable => 1, size => 255 },
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

=item * L</kanopya_mail_notifier_id>

=back

=cut

__PACKAGE__->set_primary_key("kanopya_mail_notifier_id");

=head1 RELATIONS

=head2 kanopya_mail_notifier

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "kanopya_mail_notifier",
  "Kanopya::Schema::Result::Component",
  { component_id => "kanopya_mail_notifier_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2014-03-27 16:48:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:S1eVxg0SWwL/VnIT2SWBAw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
