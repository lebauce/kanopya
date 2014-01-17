use utf8;
package Kanopya::Schema::Result::Vsphere5;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Vsphere5

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

=head1 TABLE: C<vsphere5>

=cut

__PACKAGE__->table("vsphere5");

=head1 ACCESSORS

=head2 vsphere5_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 vsphere5_login

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 vsphere5_pwd

  data_type: 'char'
  is_nullable: 1
  size: 255

=head2 vsphere5_url

  data_type: 'char'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "vsphere5_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "vsphere5_login",
  { data_type => "char", is_nullable => 1, size => 255 },
  "vsphere5_pwd",
  { data_type => "char", is_nullable => 1, size => 255 },
  "vsphere5_url",
  { data_type => "char", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</vsphere5_id>

=back

=cut

__PACKAGE__->set_primary_key("vsphere5_id");

=head1 RELATIONS

=head2 vsphere5

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Virtualization>

=cut

__PACKAGE__->belongs_to(
  "vsphere5",
  "Kanopya::Schema::Result::Virtualization",
  { virtualization_id => "vsphere5_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 vsphere5_datacenters

Type: has_many

Related object: L<Kanopya::Schema::Result::Vsphere5Datacenter>

=cut

__PACKAGE__->has_many(
  "vsphere5_datacenters",
  "Kanopya::Schema::Result::Vsphere5Datacenter",
  { "foreign.vsphere5_id" => "self.vsphere5_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vsphere5_hypervisors

Type: has_many

Related object: L<Kanopya::Schema::Result::Vsphere5Hypervisor>

=cut

__PACKAGE__->has_many(
  "vsphere5_hypervisors",
  "Kanopya::Schema::Result::Vsphere5Hypervisor",
  { "foreign.vsphere5_id" => "self.vsphere5_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vsphere5_vms

Type: has_many

Related object: L<Kanopya::Schema::Result::Vsphere5Vm>

=cut

__PACKAGE__->has_many(
  "vsphere5_vms",
  "Kanopya::Schema::Result::Vsphere5Vm",
  { "foreign.vsphere5_id" => "self.vsphere5_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-21 18:16:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SJkNZUvtzA90Rr1zWDH2Dw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
