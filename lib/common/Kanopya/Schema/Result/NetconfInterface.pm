use utf8;
package Kanopya::Schema::Result::NetconfInterface;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::NetconfInterface

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

=head1 TABLE: C<netconf_interface>

=cut

__PACKAGE__->table("netconf_interface");

=head1 ACCESSORS

=head2 netconf_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 interface_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "netconf_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "interface_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</netconf_id>

=item * L</interface_id>

=back

=cut

__PACKAGE__->set_primary_key("netconf_id", "interface_id");

=head1 RELATIONS

=head2 interface

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Interface>

=cut

__PACKAGE__->belongs_to(
  "interface",
  "Kanopya::Schema::Result::Interface",
  { interface_id => "interface_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 netconf

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Netconf>

=cut

__PACKAGE__->belongs_to(
  "netconf",
  "Kanopya::Schema::Result::Netconf",
  { netconf_id => "netconf_id" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dJparOZM62TCr8aM81R3Bw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
