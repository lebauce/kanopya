use utf8;
package Kanopya::Schema::Result::VirtualMachine;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::VirtualMachine

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

=head1 TABLE: C<virtual_machine>

=cut

__PACKAGE__->table("virtual_machine");

=head1 ACCESSORS

=head2 virtual_machine_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 hypervisor_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 vnc_port

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "virtual_machine_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "hypervisor_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "vnc_port",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</virtual_machine_id>

=back

=cut

__PACKAGE__->set_primary_key("virtual_machine_id");

=head1 RELATIONS

=head2 hypervisor

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Hypervisor>

=cut

__PACKAGE__->belongs_to(
  "hypervisor",
  "Kanopya::Schema::Result::Hypervisor",
  { hypervisor_id => "hypervisor_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 opennebula3_vm

Type: might_have

Related object: L<Kanopya::Schema::Result::Opennebula3Vm>

=cut

__PACKAGE__->might_have(
  "opennebula3_vm",
  "Kanopya::Schema::Result::Opennebula3Vm",
  { "foreign.opennebula3_vm_id" => "self.virtual_machine_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 openstack_vm

Type: might_have

Related object: L<Kanopya::Schema::Result::OpenstackVm>

=cut

__PACKAGE__->might_have(
  "openstack_vm",
  "Kanopya::Schema::Result::OpenstackVm",
  { "foreign.openstack_vm_id" => "self.virtual_machine_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 virtual_machine

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Host>

=cut

__PACKAGE__->belongs_to(
  "virtual_machine",
  "Kanopya::Schema::Result::Host",
  { host_id => "virtual_machine_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 vsphere5_vm

Type: might_have

Related object: L<Kanopya::Schema::Result::Vsphere5Vm>

=cut

__PACKAGE__->might_have(
  "vsphere5_vm",
  "Kanopya::Schema::Result::Vsphere5Vm",
  { "foreign.vsphere5_vm_id" => "self.virtual_machine_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FoxlqlvznpWAfAosEA4Mpg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
