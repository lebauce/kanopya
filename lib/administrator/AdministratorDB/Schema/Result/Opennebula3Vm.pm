package AdministratorDB::Schema::Result::Opennebula3Vm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

AdministratorDB::Schema::Result::Opennebula3Vm

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
__PACKAGE__->set_primary_key("opennebula3_vm_id");

=head1 RELATIONS

=head2 opennebula3_vm

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::VirtualMachine>

=cut

__PACKAGE__->belongs_to(
  "opennebula3_vm",
  "AdministratorDB::Schema::Result::VirtualMachine",
  { virtual_machine_id => "opennebula3_vm_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 opennebula3

Type: belongs_to

Related object: L<AdministratorDB::Schema::Result::Opennebula3>

=cut

__PACKAGE__->belongs_to(
  "opennebula3",
  "AdministratorDB::Schema::Result::Opennebula3",
  { opennebula3_id => "opennebula3_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-07-19 12:48:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:l2/lvngkKXIBV7KB9EJyEA

__PACKAGE__->belongs_to(
  "parent",
  "AdministratorDB::Schema::Result::VirtualMachine",
  { virtual_machine_id => "opennebula3_vm_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
