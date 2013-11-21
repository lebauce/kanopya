use utf8;
package Kanopya::Schema::Result::Vlan;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Vlan

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

=head1 TABLE: C<vlan>

=cut

__PACKAGE__->table("vlan");

=head1 ACCESSORS

=head2 vlan_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 vlan_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 vlan_number

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "vlan_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "vlan_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "vlan_number",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</vlan_id>

=back

=cut

__PACKAGE__->set_primary_key("vlan_id");

=head1 RELATIONS

=head2 netconf_vlans

Type: has_many

Related object: L<Kanopya::Schema::Result::NetconfVlan>

=cut

__PACKAGE__->has_many(
  "netconf_vlans",
  "Kanopya::Schema::Result::NetconfVlan",
  { "foreign.vlan_id" => "self.vlan_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vlan

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "vlan",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "vlan_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 netconfs

Type: many_to_many

Composing rels: L</netconf_vlans> -> netconf

=cut

__PACKAGE__->many_to_many("netconfs", "netconf_vlans", "netconf");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u4D4yUtVNbnTrPdRgZcD2A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
