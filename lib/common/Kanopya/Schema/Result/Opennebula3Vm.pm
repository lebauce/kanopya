use utf8;
package Kanopya::Schema::Result::Opennebula3Vm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Opennebula3Vm

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

=head1 TABLE: C<opennebula3_vm>

=cut

__PACKAGE__->table("opennebula3_vm");

=head1 ACCESSORS

=head2 opennebula3_vm_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 opennebula3_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 onevm_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "opennebula3_vm_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "opennebula3_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "onevm_id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</opennebula3_vm_id>

=back

=cut

__PACKAGE__->set_primary_key("opennebula3_vm_id");

=head1 RELATIONS

=head2 opennebula3

Type: belongs_to

Related object: L<Kanopya::Schema::Result::Opennebula3>

=cut

__PACKAGE__->belongs_to(
  "opennebula3",
  "Kanopya::Schema::Result::Opennebula3",
  { opennebula3_id => "opennebula3_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 opennebula3_kvm_vm

Type: might_have

Related object: L<Kanopya::Schema::Result::Opennebula3KvmVm>

=cut

__PACKAGE__->might_have(
  "opennebula3_kvm_vm",
  "Kanopya::Schema::Result::Opennebula3KvmVm",
  { "foreign.opennebula3_kvm_vm_id" => "self.opennebula3_vm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 opennebula3_vm

Type: belongs_to

Related object: L<Kanopya::Schema::Result::VirtualMachine>

=cut

__PACKAGE__->belongs_to(
  "opennebula3_vm",
  "Kanopya::Schema::Result::VirtualMachine",
  { virtual_machine_id => "opennebula3_vm_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ERNva9shxrDkvc6xCCOwaA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
