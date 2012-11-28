package AdministratorDB::Schema::Result::InterfaceNetwork;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::InterfaceNetwork

=cut

__PACKAGE__->table("interface_network");

=head1 ACCESSORS

=head2 interface_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 network_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "interface_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "network_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("interface_id", "network_id");

=head1 RELATIONS

=head2 interface

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Interface>

=cut

__PACKAGE__->belongs_to(
  "interface",
  "AdministratorDB::Schema::Result::Interface",
  { interface_id => "interface_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 network

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Network>

=cut

__PACKAGE__->belongs_to(
  "network",
  "AdministratorDB::Schema::Result::Network",
  { network_id => "network_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-04-24 11:28:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:miPF4okmgPxACw+6t4c+sw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
