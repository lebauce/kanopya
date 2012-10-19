use utf8;
package AdministratorDB::Schema::Result::Vsphere5Vm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Vsphere5Vm

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<vsphere5_vm>

=cut

__PACKAGE__->table("vsphere5_vm");

=head1 ACCESSORS

=head2 vsphere5_vm_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 vsphere5_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 vsphere5_guest_id

  data_type: 'char'
  is_nullable: 0
  size: 128

=cut

__PACKAGE__->add_columns(
  "vsphere5_vm_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "vsphere5_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "vsphere5_guest_id",
  { data_type => "char", is_nullable => 0, size => 128 },
);

=head1 PRIMARY KEY

=over 4

=item * L</vsphere5_vm_id>

=back

=cut

__PACKAGE__->set_primary_key("vsphere5_vm_id");

=head1 RELATIONS

=head2 vsphere5

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Vsphere5>

=cut

__PACKAGE__->belongs_to(
  "vsphere5",
  "AdministratorDB::Schema::Result::Vsphere5",
  { vsphere5_id => "vsphere5_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 vsphere5_vm

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::VirtualMachine>

=cut

__PACKAGE__->belongs_to(
  "vsphere5_vm",
  "AdministratorDB::Schema::Result::VirtualMachine",
  { virtual_machine_id => "vsphere5_vm_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-08-27 16:47:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:t6LcbBTxoCfjhL7I+krQ9g

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::VirtualMachine",
  { virtual_machine_id => "vsphere5_vm_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
