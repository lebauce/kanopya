use utf8;
package Kanopya::Schema::Result::Dhcpd3;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Dhcpd3

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

=head1 TABLE: C<dhcpd3>

=cut

__PACKAGE__->table("dhcpd3");

=head1 ACCESSORS

=head2 dhcpd3_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 dhcpd3_domain_name

  data_type: 'char'
  is_nullable: 1
  size: 128

=head2 dhcpd3_domain_server

  data_type: 'char'
  is_nullable: 1
  size: 128

=head2 dhcpd3_servername

  data_type: 'char'
  is_nullable: 1
  size: 128

=cut

__PACKAGE__->add_columns(
  "dhcpd3_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "dhcpd3_domain_name",
  { data_type => "char", is_nullable => 1, size => 128 },
  "dhcpd3_domain_server",
  { data_type => "char", is_nullable => 1, size => 128 },
  "dhcpd3_servername",
  { data_type => "char", is_nullable => 1, size => 128 },
);

=head1 PRIMARY KEY

=over 4

=item * L</dhcpd3_id>

=back

=cut

__PACKAGE__->set_primary_key("dhcpd3_id");

=head1 RELATIONS

=head2 dhcpd3

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Component>

=cut

__PACKAGE__->belongs_to(
  "dhcpd3",
  "Kanopya::Schema::Result::Component",
  { component_id => "dhcpd3_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 dhcpd3_subnets

Type: has_many

Related object: L<Kanopya::Schema::Result::Dhcpd3Subnet>

=cut

__PACKAGE__->has_many(
  "dhcpd3_subnets",
  "Kanopya::Schema::Result::Dhcpd3Subnet",
  { "foreign.dhcpd3_id" => "self.dhcpd3_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BIhU7EecC34SWdZwtHDyBA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
