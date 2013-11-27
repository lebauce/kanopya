use utf8;
package Kanopya::Schema::Result::IpmiCredentials;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::IpmiCredentials

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

=head1 TABLE: C<ipmi_credentials>

=cut

__PACKAGE__->table("ipmi_credentials");

=head1 ACCESSORS

=head2 ipmi_credentials_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 host_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 ipmi_credentials_ip_addr

  data_type: 'char'
  is_nullable: 0
  size: 15

=head2 ipmi_credentials_user

  data_type: 'char'
  is_nullable: 0
  size: 255

=head2 ipmi_credentials_password

  data_type: 'char'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "ipmi_credentials_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "host_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "ipmi_credentials_ip_addr",
  { data_type => "char", is_nullable => 0, size => 15 },
  "ipmi_credentials_user",
  { data_type => "char", is_nullable => 0, size => 255 },
  "ipmi_credentials_password",
  { data_type => "char", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ipmi_credentials_id>

=back

=cut

__PACKAGE__->set_primary_key("ipmi_credentials_id");

=head1 RELATIONS

=head2 host

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Host>

=cut

__PACKAGE__->belongs_to(
  "host",
  "Kanopya::Schema::Result::Host",
  { host_id => "host_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2013-11-28 18:28:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NxbqmEH3r945KjxWpL8ijQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
