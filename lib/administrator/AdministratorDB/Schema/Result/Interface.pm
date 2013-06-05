use utf8;
package AdministratorDB::Schema::Result::Interface;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Interface

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

=head1 TABLE: C<interface>

=cut

__PACKAGE__->table("interface");

=head1 ACCESSORS

=head2 interface_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 bonds_number

  data_type: 'integer'
  default_value: 1
  extra: {unsigned => 1}
  is_nullable: 0

=head2 interface_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "interface_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "service_provider_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "bonds_number",
  {
    data_type => "integer",
    default_value => 1,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "interface_name",
  {
    data_type => "char",
    is_nullable => 0,
    size => 32
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</interface_id>

=back

=cut

__PACKAGE__->set_primary_key("interface_id");

=head1 RELATIONS

=head2 interface

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "interface",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "interface_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 netconf_interfaces

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NetconfInterface>

=cut

__PACKAGE__->has_many(
  "netconf_interfaces",
  "AdministratorDB::Schema::Result::NetconfInterface",
  { "foreign.interface_id" => "self.interface_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 service_provider

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::ServiceProvider>

=cut

__PACKAGE__->belongs_to(
  "service_provider",
  "AdministratorDB::Schema::Result::ServiceProvider",
  { service_provider_id => "service_provider_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 netconfs

Type: many_to_many

Composing rels: L</netconf_interfaces> -> netconf

=cut

__PACKAGE__->many_to_many("netconfs", "netconf_interfaces", "netconf");


# Created by DBIx::Class::Schema::Loader v0.07024 @ 2012-11-20 14:19:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JZ2CYc0N1KHStrTXp4wOVg

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "interface_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
