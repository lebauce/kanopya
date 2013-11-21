use utf8;
package Kanopya::Schema::Result::Opennebula3KvmVm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Kanopya::Schema::Result::Opennebula3KvmVm

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

Related object: L<Kanopya::Schema::Result::Opennebula3Vm>

=cut

__PACKAGE__->belongs_to(
  "opennebula3_kvm_vm",
  "Kanopya::Schema::Result::Opennebula3Vm",
  { opennebula3_vm_id => "opennebula3_kvm_vm_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-11-20 15:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/3FeRnZC/nNKmZEm2Mt4iA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
