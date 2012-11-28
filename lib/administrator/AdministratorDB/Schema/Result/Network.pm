package AdministratorDB::Schema::Result::Network;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Network

=cut

__PACKAGE__->table("network");

=head1 ACCESSORS

=head2 network_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 network_name

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "network_id",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "network_name",
  { data_type => "char", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("network_id");
__PACKAGE__->add_unique_constraint("network_name", ["network_name"]);

=head1 RELATIONS

=head2 interface_networks

Type: has_many

Related object: L<AdministratorDB::Schema::Result::InterfaceNetwork>

=cut

__PACKAGE__->has_many(
  "interface_networks",
  "AdministratorDB::Schema::Result::InterfaceNetwork",
  { "foreign.network_id" => "self.network_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 network

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Entity>

=cut

__PACKAGE__->belongs_to(
  "network",
  "AdministratorDB::Schema::Result::Entity",
  { entity_id => "network_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 network_poolips

Type: has_many

Related object: L<AdministratorDB::Schema::Result::NetworkPoolip>

=cut

__PACKAGE__->has_many(
  "network_poolips",
  "AdministratorDB::Schema::Result::NetworkPoolip",
  { "foreign.network_id" => "self.network_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vlan

Type: might_have

Related object: L<AdministratorDB::Schema::Result::Vlan>

=cut

__PACKAGE__->might_have(
  "vlan",
  "AdministratorDB::Schema::Result::Vlan",
  { "foreign.vlan_id" => "self.network_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-04-17 14:30:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3L9zKTbkgPWfMr0Q5lWC+w

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.entity_id" => "self.network_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
