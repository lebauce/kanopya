use utf8;
package Kanopya::Schema::Result::Vsphere5Vm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Vsphere5Vm

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

=head2 vsphere5_uuid

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
  "vsphere5_uuid",
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

Related object: L<Kanopya::Schema::Result::Vsphere5>

=cut

__PACKAGE__->belongs_to(
  "vsphere5",
  "Kanopya::Schema::Result::Vsphere5",
  { vsphere5_id => "vsphere5_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 vsphere5_vm

Type: belongs_to

Related object: L<Kanopya::Schema::Result::VirtualMachine>

=cut

__PACKAGE__->belongs_to(
  "vsphere5_vm",
  "Kanopya::Schema::Result::VirtualMachine",
  { virtual_machine_id => "vsphere5_vm_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:98bUW5f7mcoqGAglfQpIoQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
