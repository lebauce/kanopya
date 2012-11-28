use utf8;
package AdministratorDB::Schema::Result::Opennebula3KvmVm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdministratorDB::Schema::Result::Opennebula3KvmVm

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<opennebula3_kvm_vm>

=cut

__PACKAGE__->table("opennebula3_kvm_vm");

=head1 ACCESSORS

=head2 opennebula3_kvm_vm_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 opennebula3_kvm_vm_cores

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "opennebula3_kvm_vm_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "opennebula3_kvm_vm_cores",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</opennebula3_kvm_vm_id>

=back

=cut

__PACKAGE__->set_primary_key("opennebula3_kvm_vm_id");

=head1 RELATIONS

=head2 opennebula3_kvm_vm

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Opennebula3Vm>

=cut

__PACKAGE__->belongs_to(
  "opennebula3_kvm_vm",
  "AdministratorDB::Schema::Result::Opennebula3Vm",
  { opennebula3_vm_id => "opennebula3_kvm_vm_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-08-20 11:54:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yGAgUV48Q6ZXqdH5gBfSaA

__PACKAGE__->belongs_to(
    "parent",
    "AdministratorDB::Schema::Result::Opennebula3Vm",
    { opennebula3_vm_id => "opennebula3_kvm_vm_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
