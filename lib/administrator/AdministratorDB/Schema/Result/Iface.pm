use utf8;
package AdministratorDB::Schema::Result::Iface;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Iface

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

=head1 TABLE: C<iface>

=cut

__PACKAGE__->table("iface");

=head1 ACCESSORS

=head2 iface_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 iface_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 iface_mac_addr

  data_type: 'char'
  is_nullable: 0
  size: 18

=head2 iface_pxe

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 host_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 interface_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "iface_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "iface_name",
  { data_type => "char", is_nullable => 0, size => 32 },
  "iface_mac_addr",
  { data_type => "char", is_nullable => 0, size => 18 },
  "iface_pxe",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "host_id",
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
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</iface_id>

=back

=cut

__PACKAGE__->set_primary_key("iface_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<iface_mac_addr>

=over 4

=item * L</iface_mac_addr>

=back

=cut

__PACKAGE__->add_unique_constraint("iface_mac_addr", ["iface_mac_addr"]);

=head2 C<iface_name>

=over 4

=item * L</iface_name>

=item * L</host_id>

=back

=cut

__PACKAGE__->add_unique_constraint("iface_name", ["iface_name", "host_id"]);

=head1 RELATIONS

=head2 host

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Host>

=cut

__PACKAGE__->belongs_to(
  "host",
  "AdministratorDB::Schema::Result::Host",
  { host_id => "host_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 iface

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "iface",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "iface_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 interface

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Interface>

=cut

__PACKAGE__->belongs_to(
  "interface",
  "AdministratorDB::Schema::Result::Interface",
  { interface_id => "interface_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 ips

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Ip>

=cut

__PACKAGE__->has_many(
  "ips",
  "AdministratorDB::Schema::Result::Ip",
  { "foreign.iface_id" => "self.iface_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netconf_ifaces

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NetconfIface>

=cut

__PACKAGE__->has_many(
  "netconf_ifaces",
  "AdministratorDB::Schema::Result::NetconfIface",
  { "foreign.iface_id" => "self.iface_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 netconfs

Type: many_to_many

Composing rels: L</netconf_ifaces> -> netconf

=cut

__PACKAGE__->many_to_many("netconfs", "netconf_ifaces", "netconf");


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-11-19 16:59:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1l+q4vG8jEuj8wnnKToDrg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "iface_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
