package AdministratorDB::Schema::Result::Interface;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Interface

=cut

__PACKAGE__->table("interface");

=head1 ACCESSORS

=head2 interface_id

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 interface_role_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 service_provider_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

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
  "interface_role_id",
  {
    data_type => "integer",
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
);
__PACKAGE__->set_primary_key("interface_id");

=head1 RELATIONS

=head2 ifaces

Type: has_many

Related object: L<AdministratorDB::Schema::Result::Iface>

=cut

__PACKAGE__->has_many(
  "ifaces",
  "AdministratorDB::Schema::Result::Iface",
  { "foreign.interface_id" => "self.interface_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

=head2 interface_role

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::InterfaceRole>

=cut

__PACKAGE__->belongs_to(
  "interface_role",
  "AdministratorDB::Schema::Result::InterfaceRole",
  { interface_role_id => "interface_role_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
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

=head2 interface_networks

Type: has_many

Related object: L<AdministratorDB::Schema::Result::InterfaceNetwork>

=cut

__PACKAGE__->has_many(
  "interface_networks",
  "AdministratorDB::Schema::Result::InterfaceNetwork",
  { "foreign.interface_id" => "self.interface_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-04-24 11:28:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8J+znHg1tcDUiFNjf/GCXA

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::Entity",
  { "foreign.entity_id" => "self.interface_id" },
  { cascade_copy => 0, cascade_delete => 1 }
);

1;
