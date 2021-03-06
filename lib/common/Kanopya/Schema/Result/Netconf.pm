use utf8;
package Kanopya::Schema::Result::Netconf;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Netconf

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

=head1 TABLE: C<netconf>

=cut

__PACKAGE__->table("netconf");

=head1 ACCESSORS

=head2 netconf_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 netconf_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 netconf_role_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "netconf_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "netconf_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "netconf_role_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</netconf_id>

=back

=cut

__PACKAGE__->set_primary_key("netconf_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<netconf_name>

=over 4

=item * L</netconf_name>

=back

=cut

__PACKAGE__->add_unique_constraint("netconf_name", ["netconf_name"]);

=head1 RELATIONS

=head2 netconf

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "netconf",
  "Kanopya::Schema::Result::Entity",
  { entity_id => "netconf_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 netconf_ifaces

Type: has_many

Related object: L<Kanopya::Schema::Result::NetconfIface>

=cut

__PACKAGE__->has_many(
  "netconf_ifaces",
  "Kanopya::Schema::Result::NetconfIface",
  { "foreign.netconf_id" => "self.netconf_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netconf_interfaces

Type: has_many

Related object: L<Kanopya::Schema::Result::NetconfInterface>

=cut

__PACKAGE__->has_many(
  "netconf_interfaces",
  "Kanopya::Schema::Result::NetconfInterface",
  { "foreign.netconf_id" => "self.netconf_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netconf_poolips

Type: has_many

Related object: L<Kanopya::Schema::Result::NetconfPoolip>

=cut

__PACKAGE__->has_many(
  "netconf_poolips",
  "Kanopya::Schema::Result::NetconfPoolip",
  { "foreign.netconf_id" => "self.netconf_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netconf_role

Type: belongs_to

Related object: L<Kanopya::Schema::Result::NetconfRole>

=cut

__PACKAGE__->belongs_to(
  "netconf_role",
  "Kanopya::Schema::Result::NetconfRole",
  { netconf_role_id => "netconf_role_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 netconf_vlans

Type: has_many

Related object: L<Kanopya::Schema::Result::NetconfVlan>

=cut

__PACKAGE__->has_many(
  "netconf_vlans",
  "Kanopya::Schema::Result::NetconfVlan",
  { "foreign.netconf_id" => "self.netconf_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ifaces

Type: many_to_many

Composing rels: L</netconf_ifaces> -> iface

=cut

__PACKAGE__->many_to_many("ifaces", "netconf_ifaces", "iface");

=head2 interfaces

Type: many_to_many

Composing rels: L</netconf_interfaces> -> interface

=cut

__PACKAGE__->many_to_many("interfaces", "netconf_interfaces", "interface");

=head2 poolips

Type: many_to_many

Composing rels: L</netconf_poolips> -> poolip

=cut

__PACKAGE__->many_to_many("poolips", "netconf_poolips", "poolip");

=head2 vlans

Type: many_to_many

Composing rels: L</netconf_vlans> -> vlan

=cut

__PACKAGE__->many_to_many("vlans", "netconf_vlans", "vlan");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tBG6TFMnl7zBaoAmWmMtqg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
